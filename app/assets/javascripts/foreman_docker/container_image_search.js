function ContainerImageSearch() {
  this.initialize = function (registryType) {
    this.registryType = registryType;
    this.form = $('form[data-registry="' + this.registryType + '"]');
    this.inputs = {
      image: this.getInput('image'),
      tag: this.getInput('tag')
    };
    this.results = this.form.find('.registry-search-results')
    this.resultsList = this.results.find('.registry-search-results-list');
    this.resultsList.on('click', this.selectImage.bind(this));

    this.searchButton = this.form.find('.image-search-button');
    this.searchButton.on('click', function (event) {
      event.preventDefault();
      this.fullResultList();
    }.bind(this))

    this.setupInputs();
  };

  this.registryId = function () {
    return $('#docker_container_wizard_states_image_registry_id').val();
  };

  this.getInput = function (input) {
    return this.form.find('input[data-' + input + ']:first');
  };

  this.getFormGroup = function (input) {
    return input.closest('.form-group');
  }

  this.getSpinner = function (input) {
    return this.getFormGroup(input).find('.autocomplete-status');
  };

  this.getInlineHelp = function (input) {
    return this.getFormGroup(input).find('.help-inline');
  }

  this.getAutocompleteResults = function (tag, input, callback, params) {
    var spinner = this.getSpinner(tag),
        imageName = this.inputs.image.val(),
        tagsOnly = tag.data('tag'),
        params = $.extend({
          search: tagsOnly ? imageName + ':' + input.term : input.term,
          registry_id: this.registryId(),
          tags: tagsOnly
        }, params)

    spinner.removeClass('pficon pficon-error-circle-o pficon-ok')
           .addClass('spinner spinner-xs').show();

    $.getJSON(tag.data("url"), params, function (data) {
      this.setAutocompleteConfirmationStatus(tag, data)
      callback(data);
    }.bind(this))
    .error(function(result) {
      $.jnotify(result.responseText, 'error', true);
    })
  };

  this.fullResultList = function (event) {
    var list = this.resultsList,
        input = this.inputs.image;

    input.autocomplete('disable')
    list.empty();

    $.ajax({
      type:'get',
      dataType:'text',
      url: this.searchButton.data('url'),
      data: {
        search: input.val(),
        registry_id: this.registryId()
      },
      success: function (result) {
        list.html(result).show();
      },
      error: function(result) {
        $.jnotify(result.responseText, 'error', true);
    }});
  };

  this.selectImage = function (event) {
    var link = $(event.target);
    if (link.hasClass('repository-name')) {
      event.preventDefault();
      this.inputs.image
        .val(link.text())
      this.inputs.tag.val('').focus();
    }
  };

  this.setAutocompleteConfirmationStatus = function (field, results) {
    var spinner = this.getSpinner(field),
        inlineHelp = this.getInlineHelp(field),
        resultType = field.data('tag') ? 'Tag' : 'Image',
        result = results.filter(function (item) {
          return item.value == field.val();
        })[0];

    inlineHelp.find('.autocomplete-confirmation').remove()
    spinner.removeClass('spinner spinner-xs pficon-error-circle-o pficon-ok');

    if (field.val() == '')
      return;

    if (result) {
      spinner.addClass('pficon pficon-ok');
      inlineHelp.append('<span class="autocomplete-confirmation">&nbsp;' +
                        resultType + ' <strong>' + field.val() + '</strong> available.' +
                        '</span>');
    } else {
      spinner.addClass('pficon pficon-error-circle-o');
      inlineHelp.append('<span class="autocomplete-confirmation">&nbsp;' +
                        resultType + ' <strong>' + field.val() + '</strong> is <strong>not</strong> available.' +
                        '</span>');
    };
  }

  this.confirmAutocomplete = function (field, autocomplete) {
    this.getAutocompleteResults(field, { term: field.val() }, function (results) {
      this.setAutocompleteConfirmationStatus(field, results)
    }.bind(this));
  };

  this.setupAutoCompleteInput = function (field) {
    var options = $.extend({
      source: function (input, callback) {
        this.getAutocompleteResults(field, input, callback)
      }.bind(this),
      delay: 500,
      minLength: field.data('min-length')
    }, options);

    field.autocomplete(options);

    field.on('blur', function () {
      this.confirmAutocomplete(field)
    }.bind(this))
  },

  this.setupInputs = function () {
    var image = this.inputs.image,
        tag = this.inputs.tag;

    this.setupAutoCompleteInput(tag)
    this.setupAutoCompleteInput(image)

    // Trigger search on pressing enter in image search
    image.on("keypress", function(e) {
      if (e.keyCode == 13) {
        e.preventDefault();
        this.fullResultList()
      }
    }.bind(this))

    image.on('focus', function () {
      image.autocomplete('enable')
    });

    tag.on('focus', function () {
      if (tag.val() == '')
        tag.autocomplete('search', '');
    });
  };

  this.initialize.apply(this, arguments);
  return this;
}

$(document).ready(function() {
  var hubSearch = new ContainerImageSearch('hub'),
      registrySearch = new ContainerImageSearch('registry');

  $('#hub_tab').click( function() {
      $('#docker_container_wizard_states_image_registry_id').val('');
  });
});
