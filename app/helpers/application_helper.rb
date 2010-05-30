module ApplicationHelper
  
  def language_suffix
    '_fa' if I18n.locale == :fa
  end

  def language_url
    if I18n.locale == :fa
      return 'http://www.' + request.domain + request.path
    else
      return 'http://fa.' +  request.domain + request.path
    end
  end

  def add_this_block
    s = %{
    <!-- AddThis Button BEGIN -->
    <script type="text/javascript">var addthis_pub="mesolore";</script>
    <a href="http://www.addthis.com/bookmark.php"
            onmouseover="return addthis_open(this, '', '[URL]', '[TITLE]');"
            onmouseout="addthis_close();"
            onclick="return addthis_sendto();">#{t(:share)}</a>
    <script type="text/javascript" src="http://s7.addthis.com/js/200/addthis_widget.js"></script>
    <!-- AddThis Button END -->
    }
  end

  def google_analytics_block
    if Rails.env == 'production'
      s = %{
    <!-- Google Analytics BEGIN -->
    <script type="text/javascript">

      var _gaq = _gaq || [];
      _gaq.push(['_setAccount', 'UA-1325142-25']);
      _gaq.push(['_setDomainName', '.qajarwomen.org']);
      _gaq.push(['_trackPageview']);

      (function() {
        var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
      })();

    </script>
    <!-- Google Analytics END -->
      }
    end
  end

  #zoomify javascript include block
  def include_zoomify?
    # check is we are on the source controller and have a valid source stored
    return %{
    <!-- Zoomify swfobject registration BEGIN -->
    <script type="text/javascript">
      swfobject.registerObject("zoomify_swf", "10.0.0", "/flash/expressInstall.swf");
    </script>
    <!-- Zoomify swfobject registration END -->
    } unless @source.nil?
  end

  #fckeditor javascript include block
  def include_fckeditor?
    # check whether we are editing or need the control
    return %{
      javascript_include_tag 'fckeditor/fckeditor.js'
    } if ['edit','new'].include?(controller.action_name) || @use_fckeditor
  end

  TYPO_TAG_KEY = TYPO_ATTRIBUTE_KEY = /[\w:_-]+/
  TYPO_ATTRIBUTE_VALUE = /(?:[A-Za-z0-9]+|(?:'[^']*?'|"[^"]*?"))/
  TYPO_ATTRIBUTE = /(?:#{TYPO_ATTRIBUTE_KEY}(?:\s*=\s*#{TYPO_ATTRIBUTE_VALUE})?)/
  TYPO_ATTRIBUTES = /(?:#{TYPO_ATTRIBUTE}(?:\s+#{TYPO_ATTRIBUTE})*)/
  TAG = %r{<[!/?\[]?(?:#{TYPO_TAG_KEY}|--)(?:\s+#{TYPO_ATTRIBUTES})?\s*(?:[!/?\]]+|--)?>}

  #strip_html
  def strip_html(html_string)
    return html_string.gsub(TAG, '').gsub(/\s+/, ' ').strip
  end

  #blip.tv player
  def blip_player(id)
    return %{
      <!-- blipTV player BEGIN -->
      <embed src="http://blip.tv/play/#{id}" type="application/x-shockwave-flash" width="480" height="390" allowscriptaccess="always" allowfullscreen="true"></embed>
      <!-- blipTV player END -->
    } unless id.nil?
  end

  def audio_player(file_name)
    return %{
      <audio controls autobuffer class="backdrop aligncenter">
        <source src="#{file_name}" />
        <source src="#{file_name}" />
        <script type="text/javascript">
          //swfobject.registerObject("zoomify_swf", "10.0.0", "/flash/expressInstall.swf");
        </script>
      </audio>
    }
  end

  def sort_link(title, column, options = {})
    condition = options[:unless] if options.has_key?(:unless)
    sort_dir = params[:d] == 'up' ? 'down' : 'up'
    link_to_unless condition, title, request.parameters.merge( {:c => column, :d => sort_dir} )
  end

  def show_check(value)
    if value
      image_tag("tick.png")
    else
      image_tag("cross.png")
    end
  end
end
