class CompositeDevice extends Dmx.Device
  constructor: (devices) ->
    @devices = devices

  addDevice: (device) ->
    @devices.push(device)

  getDmxValues: () ->
    values = []
    for i in @devices
      values.push i.getDmxValues()...
    values

  setValue: (name, value) ->
    for i in @devices
      i.setValue name, value

class Pixels extends CompositeDevice
  constructor: (options) ->
    super(Pixels.generateDevices(options))

  @generateDevices: ({prefix, offset, universe, num}) ->
    devices = []
    for i in [0..num]
      device = new Dmx.Device
        name: "#{prefix}-#{i}"
        address: "#{universe}.#{offset + (i*3)}"
      device.template = Pixels.getSingleLightTemplate()
      devices.push device
    devices

  @getSingleLightTemplate: ->
    if not Pixels.singleLightTemplate?
      Pixels.singleLightTemplate = new Dmx.DeviceTemplate {name: 'single-pixel'}
      redField = new Dmx.Field
        name: 'red'
        offset: 0
        length: 1

      blueField = new Dmx.Field
        name: 'blue'
        offset: 1
        length: 1

      greenField = new Dmx.Field
        name: 'green'
        offset: 2
        length: 1

      Pixels.singleLightTemplate.fields = {
        red: redField
        green: greenField
        blue: blueField
      }

    return Pixels.singleLightTemplate



class LoungeLight extends CompositeDevice
  constructor: (options) ->
    super(LoungeLight.generateDevices(options))

  @generateDevices: ({prefix, offset, universe}) ->
    devices = []
    for i in [0..5]
      device = new Dmx.Device
        name: "#{prefix}-#{i}"
        address: "#{universe}.#{offset + (i*3)}"
      device.template = LoungeLight.getSingleLightTemplate()
      devices.push device
    devices

  @getSingleLightTemplate: ->
    if not LoungeLight.singleLightTemplate?
      LoungeLight.singleLightTemplate = new Dmx.DeviceTemplate {name: 'single-pixel'}
      redField = new Dmx.Field
        name: 'red'
        offset: 0
        length: 1

      blueField = new Dmx.Field
        name: 'blue'
        offset: 1
        length: 1

      greenField = new Dmx.Field
        name: 'green'
        offset: 2
        length: 1

      LoungeLight.singleLightTemplate.fields = {
        red: redField
        green: greenField
        blue: blueField
      }

    return LoungeLight.singleLightTemplate

generateEasing = (startColor, endColor, devices, durationMs) ->
  start = []
  for i in devices
    i.setValue 'red', startColor.red
    i.setValue 'blue', startColor.blue
    i.setValue 'green', startColor.green
    start.push i.getDmxValues()...

  end = []
  for i in devices
    i.setValue 'red', endColor.red
    i.setValue 'blue', endColor.blue
    i.setValue 'green', endColor.green
    end.push i.getDmxValues()...

  new Dmx_Msgs.DmxEasing {
    start
    end
    durationMs
    curve: Dmx_Msgs.DmxEasing.EASING_CURVES.Linear
  }

init = () ->

  window.dmxClient = new Dmx.CommandClient(ros)

  window.loungeLight = new LoungeLight
    prefix: "living-room"
    offset: 138
    universe: 1

  window.strand1 = new Pixels
    prefix: "living-room"
    offset: 0
    universe: 1
    num: 45

  window.moving = moving = new Dmx.Device({name:'mover-01', address: "1.496"})
  moving.addField( new Dmx.Field({offset: 0, name: 'mode', length: 1, default: 255}) )
  moving.addField( new Dmx.Field({offset: 1, name: 'intensity', length: 1, default: 255}) )
  moving.addField( new Dmx.Field({offset: 2, name: 'pan', length: 2}) )
  moving.addField( new Dmx.Field({offset: 4, name: 'tilt', length: 2}) )
  moving.addField( new Dmx.Field({offset: 13, name: 'zoom', length: 2}) )
  moving.addField( new Dmx.Field({offset: 7, name: 'wheel', length: 1}) )
  moving.addField( new Dmx.Field({offset: 8, name: 'red', length: 1}) )
  moving.addField( new Dmx.Field({offset: 9, name: 'green', length: 1}) )
  moving.addField( new Dmx.Field({offset: 10, name: 'blue', length: 1}) )
  moving.addField( new Dmx.Field({offset: 11, name: 'white', length: 1}) )

$ ->

  window.ros = new ROSLIB.Ros({url : 'ws://192.168.5.118:4000'})

  ros.on 'connection', () ->
    console.log('ros socket ready')

    Dmx.factory = new ROSUtils.MessageFactory ros
    Dmx.factory.getMessageDetails 'lighting_msgs/DmxCommand', (type) ->
      console.log "type: #{type} ready"
      Dmx.emitter.emit 'ready'
      init()

  old = null

  $('#colorpicker').colorPicker {
    format: 'rgb'
    colorChange: (evt, ui) ->
      $('body').css({
        backgroundColor: ui.color
      })

      startColor = if old == null
        red: 0
        green: 0
        blue: 0
      else
        old

      command = new Dmx_Msgs.DmxCommand {
        action: Dmx_Msgs.DmxCommand.ACTIONS.Display
        loop: false
      }

      frame = new Dmx_Msgs.DmxFrame {durationMs: 10000}
      frame.easings.push generateEasing(startColor,ui, [window.loungeLight, window.moving, window.strand1], 10000)
      command.layers.push(frame)

      window.dmxClient.command = command
      window.dmxClient.send()

      old = ui
  }
