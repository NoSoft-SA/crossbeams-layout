require 'test_helper'

class Crossbeams::TextTest < Minitest::Test
  def page_config
    Crossbeams::Layout::PageConfig.new({})
  end

  def render_wrap(content)
    <<~HTML
      <div class="crossbeams-field no-flex">
      #{content}
      </div>
    HTML
  end

  def scrub(content)
    content.sub(/\A\s+/, '').gsub(/\n\s*/, "\n").sub(/\A\n/, '').sub(/\n\Z/, '')
  end

  def test_basic
    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT')
    assert_equal scrub(render_wrap('TEXT')), scrub(renderer.render)
    assert_equal [:none], renderer.wrapper
    refute renderer.preformatted
    assert_nil renderer.syntax
    refute renderer.toggle_button
    assert_equal 'Show/Hide Text', renderer.toggle_caption
  end

  def test_wrappers
    wrappers = {
        p: '<p>TEXT</p>',
        h1: '<h1>TEXT</h1>',
        h2: '<h2>TEXT</h2>',
        h3: '<h3>TEXT</h3>',
        h4: '<h4>TEXT</h4>',
        i: '<em>TEXT</em>',
        em: '<em>TEXT</em>',
        b: '<strong>TEXT</strong>',
        strong: '<strong>TEXT</strong>',
        [:p, :i] => '<p><em>TEXT</em></p>',
        [:p, :b, :i] => '<p><strong><em>TEXT</em></strong></p>',
        [:b, :em] => '<strong><em>TEXT</em></strong>'
    }
    wrappers.keys.each do |wrap|
      renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', wrapper: Array(wrap))
      assert_equal scrub(render_wrap(wrappers[wrap])), scrub(renderer.render)
    end
  end

  def test_wrapper_class
    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', wrapper: Array(:h1), wrapper_classes: 'mb0')
    assert_equal scrub(render_wrap('<h1 class="mb0">TEXT</h1>')), scrub(renderer.render)
  end

  def test_preformatted
    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', preformatted: true)
    assert_equal scrub(render_wrap("<pre>\nTEXT\n</pre>")), scrub(renderer.render)
  end

  def test_syntax
    renderer = Crossbeams::Layout::Text.new(page_config, 'SELECT', syntax: :sql)
    assert_equal scrub(render_wrap("<pre>\n<span style=\"color: #cf222e\">SELECT</span>\n</pre>")), scrub(renderer.render)
  end

  def test_toggle_button
    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', toggle_button: true)
    res = scrub(renderer.render)
    assert res.match?(/crossbeamsUtils.toggleVisibility/)
    assert res.match?(/Show\/Hide Text/)
    assert res.match?(/id='show\/hide_text'/)
    # assert res.match?(/display:none/)
    assert res.match?(/hidden/)

    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', toggle_button: true, toggle_caption: 'Toggle The Display')
    res = scrub(renderer.render)
    # assert_match(/<div class="crossbeams-field no-flex" id='toggle_the_display' style='display:none'>\sTEXT\s<\/div>/, res)
    assert_match(/<div class="crossbeams-field no-flex" id='toggle_the_display' hidden>\sTEXT\s<\/div>/, res)
    assert res.match?(/crossbeamsUtils.toggleVisibility/)
    assert res.match?(/Toggle The Display/)
  end

  def test_toggle_element
    assert_raises(ArgumentError) { Crossbeams::Layout::Text.new(page_config, 'TEXT', toggle_button: true, toggle_caption: 'Toggle The Display', toggle_element_id: 'the_element') }
    renderer = Crossbeams::Layout::Text.new(page_config, '<div id="the_element" style="display:none">TEXT</div>', toggle_button: true, toggle_caption: 'Toggle The Display', toggle_element_id: 'the_element')
    res = scrub(renderer.render)
    assert_match(/<div class="crossbeams-field no-flex">\s<div id="the_element" style="display:none">TEXT<\/div>\s<\/div>/, res)
    assert res.match?(/crossbeamsUtils.toggleVisibility/)
    assert res.match?(/Toggle The Display/)
    refute res.match?(/id='toggle_the_display'/)
    assert res.match?(/display:none/)
  end

  def test_hide_on_load
    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT')
    res = scrub(renderer.render)
    refute res.match?(/ hidden/)

    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', hide_on_load: true)
    res = scrub(renderer.render)
    assert res.match?(/ hidden/)

    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', initially_visible: false)
    res = scrub(renderer.render)
    assert res.match?(/ hidden/)

    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', initially_visible: false, hide_on_load: false)
    res = scrub(renderer.render)
    assert res.match?(/ hidden/)

    renderer = Crossbeams::Layout::Text.new(page_config, 'TEXT', initially_visible: true)
    res = scrub(renderer.render)
    refute res.match?(/ hidden/)
  end
end
