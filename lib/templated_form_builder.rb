module TemplatedFormBuilder

  class InstanceTag < ::ActionView::Helpers::InstanceTag

    def to_radio_button_tag(tag_value, options = {})
      options = DEFAULT_RADIO_OPTIONS.merge(options.stringify_keys)
      options["type"]     = "radio"
      options["value"]    = tag_value
      if options.has_key?("checked")
        cv = options.delete "checked"
        checked = cv == true || cv == "checked"
      else
        checked = self.class.radio_button_checked?(value(object), tag_value)
      end
      options["checked"]  = "checked" if checked
      pretty_tag_value    = tag_value.to_s.gsub(/\s/, "_").gsub(/\W/, "").downcase
      options["id"]     ||= defined?(@auto_index) ?
        "#{tag_id_with_index(@auto_index)}_#{pretty_tag_value}" :
        "#{tag_id}_#{pretty_tag_value}"
      add_default_name_and_id(options)
      options['class'] = tag_id
      return options['id'], tag("input", options)
    end


  end

  class Builder < ::ActionView::Helpers::FormBuilder

    (field_helpers - %w[label hidden_field check_box radio_button fields_for apply_form_for_options!] + %w[collection_select]).each do |selector|
      class_eval <<-end_src, __FILE__, __LINE__
          def #{selector}_with_template(method, *args)
            options = args.extract_options!
            template = options.delete(:template)
            render_element :#{selector},
                            method,
                            extract_label(method, options),
                            options,
                            #{selector}_without_template(method, *(args << options)),
                            template
          end

          alias_method_chain :#{selector}, :template
      end_src
    end

    def radio_button_group(method, *values)
      result = label(method) + values.flatten.map { |v| radio_button(method, v, :label => object.class.human_attribute_name("#{method}_values.#{v}")) }.join
    end

    def check_box_with_template(method, options = {}, checked_value = "1", unchecked_value = "0")
      render_element :check_box,
                      method,
                      extract_label(method, options),
                      options,
                      check_box_without_template(method, options, checked_value, unchecked_value),
                      :trailing_label
    end

    def radio_button(method, tag_value, options = {})
      label = extract_label(method, options)
      radio_button_id, element = tag(method).to_radio_button_tag(tag_value, options)
      render_element :radio_button,
                      method,
                      label,
                      options.merge(:for => radio_button_id),
                      element,
                      :trailing_label
    end

    def hidden_field_with_template(method, options = { })
      render_element :hidden_field, method, nil, options, hidden_field_without_template(method, options)
    end

    def submit_with_translation(action)
      submit_without_translation I18n.t(:"forms.actions.#{action}"), :class => 'button', :id => "#{@object_name}_submit_#{action}"
    end

    alias_method_chain :check_box, :template
    alias_method_chain :hidden_field, :template
    alias_method_chain :submit, :translation

    def section(name, &block)
      locals = {
        :section_title => name.is_a?(Symbol) ? I18n.t(:"forms.sections.#{name}") : name.to_s,
        :section_contents => @template.capture(&block),
        :section_name => name.to_s.downcase.gsub(/[^\w\d\s]/, '').gsub(/\s+/, '_')
      }

      @template.concat(@template.render(:partial => 'forms/section', :locals => locals))
    end

    protected

    def render_element(selector, method, label_text, options, element, partial = nil)
      label_text = object.class.human_attribute_name(label_text.to_s) if label_text.kind_of? Symbol

      locals = {
        :label => label_text.blank? ? '' : tag(method).to_label_tag(label_text, { :index => self.options[:index], :for => options[:for] }.reject { |k,v| [:index, :for].include?(k) && v.blank? } ),
        :element => element,
        :errors => object.nil? ? [] : [object.errors.on(method)].flatten.compact.uniq
      }

      render_element_partial(partial || selector, locals)
    end


    def render_element_partial(partial, locals)
      @template.render :partial => "forms/#{partial}", :locals => locals
    rescue ActionView::ActionViewError
      @template.render :partial => 'forms/element', :locals => locals
    end

    def extract_label(method, options)
      options.delete(:label) do
        object.class.human_attribute_name(method.to_s)
      end
    end

    def tag(method)
      InstanceTag.new(object_name, method, @template, object)
    end

  end

end
