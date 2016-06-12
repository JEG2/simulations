defmodule TrafficJam.Window do
  @behaviour :wx_object

  defstruct ~w[frame panel]a

  require Logger
  require Record
  Record.defrecordp(
    :wx, Record.extract(:wx, from_lib: "wx/include/wx.hrl")
  )
  Record.defrecordp(
    :wxClose, Record.extract(:wxClose, from_lib: "wx/include/wx.hrl")
  )

  # Client API

  def start_link(paint_delay, size, car_width) do
    window =
      :wx_object.start_link(__MODULE__, [paint_delay, size, car_width], [ ])
    {:ok, :wx_object.get_pid(window)}
  end

  # Server API

  def init([paint_delay | args]) do
    Process.flag(:trap_exit, true)

    :timer.send_interval(paint_delay, :tick)

    :wx.new

    :wx.batch(fn -> do_init(args) end)
  end

  def handle_call(message, _from, state) do
    Logger.debug "Unhandled call:  #{inspect message}"
    {:reply, :ok, state}
  end

  def handle_cast(message, state) do
    Logger.debug "Unhandled cast:  #{inspect message}"
    {:noreply, state}
  end

  def handle_event(wx(event: wxClose()), state) do
    System.halt(0)
    {:noreply, state}
  end
  def handle_event(wx, state) do
    Logger.debug "Unhandled event:  #{inspect wx}"
    {:noreply, state}
  end

  def handle_info(:tick, state = %__MODULE__{frame: frame}) do
    :wxFrame.refresh(frame, eraseBackground: false)
    {:noreply, state}
  end
  def handle_info(info, state) do
    Logger.debug "Unhandled info:  #{inspect info}"
    {:noreply, state}
  end

  def code_change(_old_vsn, _state, _extra) do
    {:error, :not_implemented}
  end

  def terminate(_reason, %__MODULE__{frame: frame, panel: panel}) do
    :wx_object.call(panel, :shutdown)
    :wxFrame.destroy(frame)
    :wx.destroy
  end

  # Helpers

  defp do_init([{width, height}, car_width]) do
    frame = :wxFrame.new(:wx.null, :wx_const.wxID_ANY, 'Traffic Jam')
    panel = TrafficJam.Canvas.start_link(frame, car_width)

    :wxFrame.setClientSize(frame, {width, height})
    sizer = :wxBoxSizer.new(:wx_const.wxVERTICAL)
    :wxSizer.add(sizer, panel, flag: :wx_const.wxEXPAND, proportion: 1)
    :wxPanel.setSizer(frame, sizer)
    :wxSizer.layout(sizer)
    frame_size = :wxFrame.getSize(frame)
    :wxFrame.setMinSize(frame, frame_size)
    :wxFrame.setMaxSize(frame, frame_size)

    :wxFrame.connect(frame, :close_window)

    :wxFrame.center(frame)
    :wxFrame.show(frame)

    {frame, %__MODULE__{frame: frame, panel: panel}}
  end
end
