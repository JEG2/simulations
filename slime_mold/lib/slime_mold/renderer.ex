defmodule SlimeMold.Renderer do
  use GenServer

  defstruct frame: nil, panel: nil

  @black {0, 0, 0, 255}
  @white {255, 255, 255, 255}
  @orange {255, 127, 0, 255}

  require Record
  Record.defrecordp(
    :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxClose, Record.extract(:wxClose, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxPaint, Record.extract(:wxPaint, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxKey, Record.extract(:wxKey, from_lib: "wx/include/wx.hrl")
  )

  # Client API

  def start_link do
    GenServer.start_link(__MODULE__, [ ])
  end

  # Server API

  def init([ ]) do
    :wx.new

    delay = Application.fetch_env!(:slime_mold, :paint_delay)
    scale = Application.fetch_env!(:slime_mold, :scale)

    :timer.send_interval(delay, :tick)

    :wx.batch(fn ->
      frame = :wxFrame.new(:wx.null, :wx_const.wxID_ANY, 'Slime Mold')
      panel = :wxPanel.new(frame)

      {width, height} = SlimeMold.Board.get_size
      :wxFrame.setClientSize(frame, {width * scale, height * scale})
      sizer = :wxBoxSizer.new(:wx_const.wxVERTICAL)
      :wxSizer.add(sizer, panel, flag: :wx_const.wxEXPAND, proportion: 1)
      :wxPanel.setSizer(frame, sizer)
      :wxSizer.layout(sizer)
      frame_size = {frame_width, frame_height} = :wxFrame.getSize(frame)
      :wxFrame.setMinSize(frame, frame_size)
      :wxFrame.setMaxSize(frame, frame_size)

      bitmap = :wxBitmap.new(frame_width, frame_height)
      user_data = %{scale: scale, bitmap: bitmap}
      :wxPanel.connect(panel, :paint, [callback: &paint/2, userData: user_data])
      :wxFrame.connect(frame, :close_window)
      :wxPanel.connect(panel, :key_down)

      :wxFrame.center(frame)
      :wxFrame.show(frame)

      {:ok, %__MODULE__{frame: frame, panel: panel}}
    end)
  end

  def paint(
    wx(event: wxPaint(), obj: panel, userData: %{scale: scale, bitmap: bitmap}),
    _paint_event
  ) do
    {width, height} = :wxPanel.getClientSize(panel)
    bitmap_context = :wxMemoryDC.new(bitmap)
    panel_context = :wxPaintDC.new(panel)

    paint_board(bitmap_context, width, height, scale)

    :wxPaintDC.blit(
      panel_context,
      {0, 0},
      {width, height},
      bitmap_context,
      {0, 0}
    )

    :wxMemoryDC.destroy(bitmap_context)
    :wxPaintDC.destroy(panel_context)
  end

  defp paint_board(context, width, height, scale) do
    changed = SlimeMold.Board.get_changed

    if Map.get(changed, :background) do
      paint_background(context, width, height)
    end
    Enum.each(changed.blanks, fn xy -> paint_blank(context, scale, xy) end)
    Enum.each(changed.pheromones, fn {xy, pheromone} ->
      paint_pheromone(context, scale, xy, pheromone)
    end)
    Enum.each(changed.cells, fn xy -> paint_cell(context, scale, xy) end)
  end

  defp paint_background(context, width, height) do
    :wxDC.setPen(context, :wxPen.new(@black))
    :wxDC.setBrush(context, :wxBrush.new(@black))
    :wxDC.drawRectangle(context, {0, 0}, {width, height})
  end

  defp paint_blank(context, scale, xy) do
    # ensure we get stray pixels
    paint_scaled(context, scale, xy, @black)
    paint_scaled(context, scale, xy, @black)
    paint_scaled(context, scale, xy, @black)
  end

  defp paint_cell(context, scale, xy) do
    paint_scaled(context, scale, xy, @orange)
  end

  defp paint_pheromone(context, scale, xy, pheromone) do
    color =
      case pheromone do
        n when n <= 0 -> raise "Illegal color"
        n when n <= 1 -> {0, 85, 0, 255}
        n when n <= 2 -> {0, 170, 0, 255}
        n when n <= 3 -> {0, 255, 0, 255}
        n when n > 3 -> @white
      end
    paint_scaled(context, scale, xy, color)
  end

  defp paint_scaled(context, scale, {x, y}, color) do
    :wxDC.setPen(context, :wxPen.new(color))
    :wxDC.setBrush(context, :wxBrush.new(color))
    :wxDC.drawRectangle(context, {x * scale, y * scale}, {scale, scale})
  end

  def handle_info(:tick, state) do
    :wxFrame.refresh(state.frame, eraseBackground: false)
    {:noreply, state}
  end
  def handle_info(wx(event: wxClose()), state) do
    System.halt(0)
    {:noreply, state}
  end
  def handle_info(
    wx(event: wxKey(
      keyCode: key,
      controlDown: control,
      shiftDown: shift,
      metaDown: meta,
      altDown: alt
    )),
    state
  ) do
    case key do
      ?Q when not (shift or alt or control or meta) -> System.halt(0)
      _ -> :ok
    end
    {:noreply, state}
  end
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :wx.destroy
  end
end
