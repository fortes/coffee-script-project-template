page = new WebPage()

# Page writes JSON to console
page.onConsoleMessage = (msg) ->
  console.log msg if /^PHANTOM:/.test msg
  # Exit when finished
  obj = JSON.parse msg.substr 9
  phantom.exit 0 if obj.name is 'done'
  return

page.open "test/index.html", (status) ->
  if status isnt "success"
    console.error "Could not open page"
    phantom.exit 1
    return

  # Set up listeners to QUnit events
  page.evaluate ->
    # Helper for sending JSON out to phantom
    phantomLog = (name, result) ->
      console.log "PHANTOM: #{window.JSON.stringify { name, result }}"
      return

    window.addEventListener 'error', (error) ->
      phantomLog 'error', { error }
      return

    # Hook into QUnit events
    ['log', 'testStart', 'testDone', 'moduleStart', 'moduleDone', 'begin', 'done'].forEach (ev) ->
      QUnit[ev] (res) -> phantomLog ev, res
