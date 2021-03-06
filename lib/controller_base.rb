require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res)
    @req = req
    @res = res
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "Double Render" if already_built_response?

    res["Location"] = url
    res.status = 302
    @already_built_response = true
    
    session.store_session(res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "Double Render" if already_built_response?

    res.write(content)
    res['Content-Type'] = content_type
    @already_built_response = true

    session.store_session(res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    ctrl_name = self.class.name.underscore
    ctrl_dir = File.dirname(__FILE__)

    file_name = "#{ctrl_dir}/../views/#{ctrl_name}/#{template_name}.html.erb"
    file = File.read(file_name)

    template = ERB.new(file).result(binding)

    render_content(template, 'text/html')

    session.store_session(res)
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end
