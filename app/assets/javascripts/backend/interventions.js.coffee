# This module permits to execute an procedure to generate operations
# with the user interaction.

((E, $) ->
  'use strict'

  E.value = (element) ->
    if element.is(":ui-selector")
      return element.selector("value")
    else
      return element.val()

  # Interventions permit to enhances data input through context computation
  # The concept is: When an update is done, we ask server which are the impact on
  # other fields and on updater itself if necessary
  E.interventions =

    toggleHandlers: (form, attributes, prefix = '') ->
      for name, value of attributes
        subprefix = prefix + name
        if /\w+_attributes$/.test(name)
          for id, attrs of value
            E.interventions.toggleHandlers(form, attrs, subprefix + '_' + id + '_')
        else
          select = form.find("##{prefix}quantity_handler")
          console.warn "Cannot find ##{prefix}quantity_handler <select>" unless select.length > 0
          option = select.find("option[value='#{name}']")
          console.warn "Cannot find option #{name} of ##{prefix}quantity_handler <select>" unless option.length > 0
          if value && !option.is(':visible')
            option.show()
          else if !value && option.is(':visible')
            option.hide()

    unserializeRecord: (form, attributes, prefix = '', updater_id = null) ->
      for name, value of attributes
        subprefix = prefix + name
        if subprefix is updater_id
          # Nothing to update
          # console.warn "Nothing to do with #{subprefix}"
        else if /\w+_attributes$/.test(name)
          E.interventions.unserializeList(form, value, subprefix + '_', updater_id)
        else
          form.find("##{subprefix}").each (index) ->
            element = $(this)
            if element.is(':ui-selector')
              if value != element.selector('value')
                if value is null
                  console.log "Clear ##{subprefix}"
                  element.selector('clear')
                else
                  console.log "Updates ##{subprefix} with: ", value
                  element.selector('value', value)
            else if element.is(":ui-mapeditor")
              value = $.parseJSON(value)
              if (value.geometries? and value.geometries.length > 0) || (value.coordinates? and value.coordinates.length > 0)
                element.mapeditor "edit", value
                try
                  element.mapeditor "view", "edit"
            else if element.is('select')
              element.find("option[value='#{value}']")[0].selected = true
            else
              valueType = typeof value
              update = true
              update = false if value is null and element.val() is ""
              if valueType == "number"
                update = false if value == element.numericalValue()
              else
                update = false if value == element.val()
              if update
                console.log "Updates ##{subprefix} with: ", value
                element.val(value)

    unserializeList: (form, list, prefix = '', updater_id) ->
      for id, attributes of list
        E.interventions.unserializeRecord(form, attributes, prefix + id + '_', updater_id)

    updateDateScopes: (newTime) ->
      $("input.scoped-parameter").each (index, item) ->
        scopeUri = decodeURI($(item).data("selector"))
        re =  /(scope\[availables\]\[\]\[at\]=)(.*)(&)/
        scopeUri = scopeUri.replace(re, "$1"+newTime+"$3")
        $(item).attr("data-selector", encodeURI(scopeUri))

    # Ask for a refresh of values depending on given field
    refresh: (origin) ->
      this.refreshHard(origin)
      # this.refreshHardz(origin.data('procedure'), origin.data('intervention-updater'), origin)

    # Ask for a refresh of values depending on given update
    refreshHard: (updater) ->
      unless updater?
        console.error 'Missing updater'
        return false
      updaterId = updater.data('intervention-updater')
      unless updaterId?
        console.warn 'No updater id, so no refresh'
        return false
      form = updater.closest('form')
      form.find("input[name='updater']").val(updaterId)
      computing = form.find('*[data-procedure]').first()
      unless computing.length > 0
        console.error 'Cannot procedure element where compute URL is defined'
        return false
      if computing.prop('state') isnt 'waiting'
        $.ajax
          url: computing.data('procedure')
          type: "PATCH"
          data: form.serialize()
          beforeSend: ->
            computing.prop 'state', 'waiting'
          error: (request, status, error) ->
            computing.prop 'state', 'ready'
            false
          success: (data, status, request) ->
            console.group('Unserialize intervention updated by ' + updaterId)
            # Updates elements with new values
            E.interventions.toggleHandlers(form, data.handlers, 'intervention_')
            E.interventions.unserializeRecord(form, data.intervention, 'intervention_', data.updater_id)
            # if updaterElement? and initialValue != E.value($("*[data-intervention-updater='#{intervention.updater}']").first())
            #   E.interventions.refresh updaterElement
            computing.prop 'state', 'ready'
            console.groupEnd()


  ##############################################################################
  # Triggers
  #
  $(document).on 'cocoon:after-insert', ->
    $('input[data-map-editor]').each ->
      $(this).mapeditor()
    $("input.intervention-started-at").each ->
      $(this).each ->
        #date = $(this).data("datetimepicker").getFormattedDate()
        date = $(this).val()
        E.interventions.updateDateScopes(date)

  $(document).on 'mapchange', '*[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  #  selector:initialized
  $(document).on 'selector:change', '*[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).on 'keyup', 'input[data-selector]', (e) ->
    $(this).each ->
      E.interventions.refresh $(this)


  $(document).on 'keyup change', 'input[data-intervention-updater]:not([data-selector])', (e) ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).on 'keyup change', 'select[data-intervention-updater]', ->
    $(this).each ->
      E.interventions.refresh $(this)

  $(document).on "keyup change", "input.intervention-started-at", ->
    $(this).each ->
      #date = $(this).data("datetimepicker").getFormattedDate()
      date = $(this).val()
      E.interventions.updateDateScopes(date)

  # $(document).on 'change', '*[data-procedure-global="at"]', ->
  #   $(this).each ->
  #     E.interventions.refresh $(this)

  # $(document).behave 'load', '*[data-procedure]', (event) ->
  #   $(this).each ->
  #     E.interventions.refresh $(this)

  # # Filters supports with given production
  # # Hides supports line if needed
  # $(document).behave "load selector:set", "*[data-intervention-updater='global:production']", (event) ->
  #   production = $(this)
  #   id = production.selector('value')
  #   form = production.closest('form')
  #   url = "/backend/production_supports/unroll?scope[of_current_campaigns]=true"
  #   support = form.find("*[data-intervention-updater='global:support']").first()
  #   if /^\d+$/.test(id)
  #     url += "&scope[of_productions]=#{id}"
  #     form.addClass("with-supports")
  #   else
  #     form.removeClass("with-supports")
  #   support.attr("data-selector", url)
  #   support.data("selector", url)

  $(document).ready ->

    if $('.taskboard').length > 0

      taskboard = new InterventionsTaskboard
      taskboard.addHeaderActionsEvent()
      taskboard.addEditIconClickEvent()
      taskboard.addDeleteIconClickEvent()
      taskboard.onSelectTaskEvent()

      # taskboard = new Taskboard('interventionsTaskboard')
      # taskboard.addSelectTaskEvent()
      # taskboard.addTaskModalEvent()
      # taskboard.addEditIconClickEvent()
      # taskboard.addDeleteIconClickEvent()


  class InterventionsTaskboard
    constructor: ->
      @taskboard = new ekylibre.taskboard('#interventionsTaskboard', true)
      @taskboardModal = new ekylibre.modal('#taskboard-modal')

    getTaskboard: ->
      return @taskboard

    getTaskboardModal: ->
      return @taskboardModal

    addHeaderActionsEvent: ->

      instance = this

      @taskboard.addSelectTaskEvent((event) ->

          selectedField = $(event.target)
          columnIndex = instance.getTaskboard().getTaskColumnIndex(selectedField)
          header = instance.getTaskboard().getHeaderByIndex(columnIndex)
          checkedFieldsCount = instance.getTaskboard().getCheckedSelectFieldsCount(selectedField)

          if (checkedFieldsCount == 0)

            instance.getTaskboard().hiddenHeaderIcons(header)
          else
            instance.getTaskboard().displayHeaderIcons(header)
      )

    addEditIconClickEvent: ->
      @taskboard.getHeaderActions().find('.edit-tasks').on('click', ->
        alert "Etes-vous sur de vouloir modifier ces interventions ?"
      )


    addDeleteIconClickEvent: ->
      @taskboard.getHeaderActions().find('.delete-tasks').on('click', ->
        alert "Etes-vous sur de vouloir supprimer ces interventions ?"
      )

    onSelectTaskEvent: ->

      instance = this

      @taskboard.addTaskClickEvent((event) ->
        task = $(event.target)

        if (task.is(':input[type="checkbox"]'))
          return

        intervention = JSON.parse(task.attr('data-intervention'))

        $.ajax
          url: "/backend/interventions/show_intervention_modal",
          data: {intervention_id: intervention.id}
          success: (data, status, request) ->

            modal = new ekylibre.modal('#taskboard-modal')
            modal.resetModal()

            modal.getHeader().prepend('<h4 class="modal-title">' + intervention.name + '</h4>')

            labels = $('<div class="labels"></div>')

            $(labels).append('<span class="label label-default">Réalisé</span>')
            $(labels).append('<span class="label label-success">Conforme</span>')
            $(labels).insertAfter(modal.getHeader().find('.modal-title'))

            # $('<span class="label label-warning">Modifiée</span>').insertBefore('#taskboard-modal .modal-header .modal-title')
            # $('<span class="label label-primary">Nouvelle intervention</span>').insertBefore('#taskboard-modal .modal-header .modal-title')
            # $('<span class="label label-success">Conforme</span>').insertBefore('#taskboard-modal .modal-header .modal-title')


            modal.getBody().append(data)

            # buttons = {
            #   [
            #     "href" => '/backend/interventions/'+intervention.id+'/edit',
            #     "class" => 'btn-default',
            #     "label" => 'Modifier'
            #   ],
            #   [
            #     "href" => '/backend/interventions/'+intervention.id+'/edit',
            #     "class" => 'btn-primary',
            #     "label" => 'Changer le statut'
            #   ],
            #   [
            #     "href" => '/backend/interventions/'+intervention.id+'/edit',
            #     "class" => 'btn-danger',
            #     "label" => 'Supprimer'
            #   ]
            # }

            editButton = $('<a href="/backend/interventions/'+intervention.id+'/edit" class="btn btn-default">Modifier</a>')

            modal.getFooter().append('<div class="task-actions"></div>')
            modal.getFooter().find('.task-actions').append(editButton)
            # $('#taskboard-modal .modal-footer .task-actions').append(editButton)
            # $('#taskboard-modal .modal-footer .task-actions').append(editButton)

            $('#taskboard-modal').modal 'show'
      )

  true
) ekylibre, jQuery
