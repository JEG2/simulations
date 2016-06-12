defmodule TrafficJam.Canvas do
  @behaviour :wx_object

  @black {0, 0, 0, 255}
  @white {255, 255, 255, 255}

  defstruct ~w[panel car_width]a

  require Logger
  require Record
  Record.defrecordp(
    :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxPaint, Record.extract(:wxPaint, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxKey, Record.extract(:wxKey, from_lib: "wx/include/wx.hrl")
  )

  # Client API

  def start_link(parent, car_width) do
    :wx_object.start_link(__MODULE__, [parent, car_width], [ ])
  end

  # Server API

  def init(args) do
    :wx.batch(fn -> do_init(args) end)
  end

  def handle_call(:shutdown, _from, state = %__MODULE__{panel: panel}) do
    :wxPanel.destroy(panel)
    {:reply, :ok, state}
  end
  def handle_call(message, _from, state) do
    Logger.debug "Unhandled call:  #{inspect message}"
    {:reply, :ok, state}
  end

  def handle_cast(message, state) do
    Logger.debug "Unhandled cast:  #{inspect message}"
    {:noreply, state}
  end

  def handle_sync_event(wx(event: wxPaint()), _paint_event, state) do
    paint(state)
    :ok
  end

  def handle_event(
    wx(
      event: wxKey(
        keyCode: key,
        controlDown: control,
        shiftDown: shift,
        metaDown: meta,
        altDown: alt
      )
    ),
    state
  ) do
    new_state = do_key_down(key, shift, alt, control, meta, state)
    {:noreply, new_state}
  end
  def handle_event(wx, state) do
    Logger.debug "Unhandled event:  #{inspect wx}"
    {:noreply, state}
  end

  def handle_info(info, state) do
    Logger.debug "Unhandled info:  #{inspect info}"
    {:noreply, state}
  end

  def code_change(_old_vsn, _state, _extra) do
    {:error, :not_implemented}
  end

  def terminate(_reason, _state) do
    :ok
  end

  # Helpers

  defp do_init([parent, car_width]) do
    panel = :wxPanel.new(parent)

    :wxFrame.connect(panel, :paint, [:callback])
    :wxPanel.connect(panel, :key_down)

    {panel, %__MODULE__{panel: panel, car_width: car_width}}
  end

  defp do_key_down(key, shift, alt, control, meta, state) do
    case key do
      ?Q when not (shift or alt or control or meta) -> System.halt(0)
      _ -> :ok
    end
    state
  end

  defp paint(%__MODULE__{panel: panel, car_width: car_width}) do
    {width, height} = :wxPanel.getClientSize(panel)
    drawing_context = :wxPaintDC.new(panel)

    paint_road(drawing_context, width, height)
    paint_cars(drawing_context, car_width)

    :wxPaintDC.destroy(drawing_context)
  end

  defp paint_road(context, width, height) do
    :wxDC.setPen(context, :wxPen.new(@black))
    :wxDC.setBrush(context, :wxBrush.new(@black))
    :wxDC.drawRectangle(context, {0, 0}, {width, height})
  end

  defp paint_cars(context, car_width) do
    TrafficJam.Road.get_cars
    |> Enum.each(fn car ->
      :wxDC.setPen(context, :wxPen.new(@white))
      :wxDC.setBrush(context, :wxBrush.new(@white))
      :wxDC.drawRectangle(context, {car, 49}, {car_width, 2})
    end)
  end
end
