require "test_helper"

# Guard rails for the view layer: partials are reusable components, so they
# must declare their inputs (strict locals) and never read controller instance
# variables. A missing or misspelled local then raises at render time instead of
# silently rendering nil.
class PartialsTest < ActiveSupport::TestCase
  VIEWS = Rails.root.join("app/views")
  # Mailer templates and PWA files are not rendered from controllers.
  SKIPPED = %w[ devise/mailer pwa ].freeze

  def partials
    Dir[VIEWS.join("**/_*.erb")].reject do |path|
      SKIPPED.any? { |dir| path.start_with?(VIEWS.join(dir).to_s) }
    end
  end

  test "there are partials to check" do
    assert_operator partials.size, :>=, 15
  end

  test "every partial declares its locals" do
    missing = partials.reject { |path| File.read(path).match?(/\A<%#\s*locals:\s*\(.*\)\s*%>/) }
    assert_empty missing.map { |p| p.delete_prefix("#{VIEWS}/") },
      "Add a strict-locals magic comment, e.g. <%# locals: (plan:) %>, as the first line"
  end

  test "partials do not read instance variables" do
    offenders = partials.filter_map do |path|
      code = File.read(path).scan(/<%.*?%>/m).reject { |tag| tag.start_with?("<%#") }.join("\n")
      ivars = code.scan(/(?<![\w@])@[a-z_]\w*/).uniq
      "#{path.delete_prefix("#{VIEWS}/")}: #{ivars.join(', ')}" if ivars.any?
    end
    assert_empty offenders, "Pass these in as locals instead of instance variables"
  end

  test "a partial rendered without a required local raises" do
    view = ApplicationController.new.view_context
    error = assert_raises(ActionView::Template::Error) { view.render("shared/material_icon") }
    assert_match(/missing local: :material/, error.message)
  end

  test "views use no inline event handlers (the content security policy blocks them)" do
    offenders = Dir[Rails.root.join("app/views/**/*.erb")].flat_map do |path|
      File.readlines(path).each_with_index.filter_map do |line, index|
        "#{path.delete_prefix("#{Rails.root}/")}:#{index + 1}" if line.match?(/\bon(change|input|blur|click|submit|focus|keydown|keyup)\s*[:=]/)
      end
    end

    assert_empty offenders, "Use Stimulus data-action instead of inline handlers"
  end
end
