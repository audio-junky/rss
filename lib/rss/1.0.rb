require "rss/parser"

module RSS

	module RSS10
		NSPOOL = {}
		ELEMENTS = []

		def self.append_features(klass)
			super
			
			klass.install_must_call_validator('', ::RSS::URI)
		end

	end

	class RDF < Element

		include RSS10
		include RootElementMixin
		include XMLStyleSheetMixin

		class << self

			def required_uri
				URI
			end

		end

		TAG_NAME.replace('RDF')

		PREFIX = 'rdf'
		URI = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"

		install_ns('', ::RSS::URI)
		install_ns(PREFIX, URI)

		[
			["channel", nil],
			["image", "?"],
			["item", "+"],
			["textinput", "?"],
		].each do |tag, occurs|
			install_model(tag, occurs)
		end

		%w(channel image textinput).each do |x|
			install_have_child_element(x)
		end

		install_have_children_element("item")

		attr_accessor :rss_version, :version, :encoding, :standalone
		
		def initialize(version=nil, encoding=nil, standalone=nil)
			super('1.0', version, encoding, standalone)
		end

		def to_s(convert=true)
			rv = <<-EORDF
#{xmldecl}
#{xml_stylesheet_pi}<#{PREFIX}:RDF#{ns_declaration}>
#{channel_element(false)}
#{image_element(false)}
#{item_elements(false)}
#{textinput_element(false)}
#{other_element(false, "\t")}
</#{PREFIX}:RDF>
EORDF
      rv = @converter.convert(rv) if convert and @converter
      rv
		end

		private
		def rdf_validate(tags)
			_validate(tags, [])
		end

		def children
			[@channel, @image, @textinput, *@item]
		end

		def _tags
			rv = [
				[::RSS::URI, "channel"],
				[::RSS::URI, "image"],
			].delete_if {|x| send(x[1]).nil?}
			@item.each do |x|
				rv << [::RSS::URI, "item"]
			end
			rv << [::RSS::URI, "textinput"] if @textinput
			rv
		end

		class Seq < Element

			include RSS10

			class << self
				
				def required_uri
					URI
				end
				
			end

			TAG_NAME.replace('Seq')
			
			install_have_children_element("li")
			
			install_must_call_validator('rdf', ::RSS::RDF::URI)
			
			def initialize(li=[])
				super()
				@li = li
			end
			
			def to_s(convert=true)
				<<-EOT
			<#{PREFIX}:Seq>
#{li_elements(convert, "\t\t\t\t")}
#{other_element(convert, "\t\t\t\t")}
			</#{PREFIX}:Seq>
EOT
			end

  		private
			def children
				@li
			end
					
			def rdf_validate(tags)
				_validate(tags, [["li", '*']])
			end

			def _tags
				rv = []
				@li.each do |x|
					rv << [URI, "li"]
				end
				rv
			end

		end

		class Li < Element

			include RSS10

			class << self
					
				def required_uri
					URI
				end
				
			end
			
			[
				["resource", [URI, nil], true]
			].each do |name, uri, required|
				install_get_attribute(name, uri, required)
			end
			
			def initialize(resource=nil)
				super()
				@resource = resource
			end
			
			def to_s(convert=true)
				if @resource
					rv = %Q!<#{PREFIX}:li resource="#{h @resource}" />\n!
					rv = @converter.convert(rv) if convert and @converter
					rv
				else
					''
				end
			end

			private
			def _attrs
				[
					["resource", true]
				]
			end
			
		end

		class Channel < Element

			include RSS10
			
			class << self

				def required_uri
					::RSS::URI
				end

			end

 			[
				["about", URI, true]
			].each do |name, uri, required|
				install_get_attribute(name, uri, required)
			end

			%w(title link description).each do |x|
				install_text_element(x)
			end

			%w(image items textinput).each do |x|
				install_have_child_element(x)
			end
			
			[
				['title', nil],
				['link', nil],
				['description', nil],
				['image', '?'],
				['items', nil],
				['textinput', '?'],
			].each do |tag, occurs|
				install_model(tag, occurs)
			end
			
			def initialize(about=nil)
				super()
				@about = about
			end

			def to_s(convert=true)
				about = ''
				about << %Q!#{PREFIX}:about="#{h @about}"! if @about
				rv = <<-EOT
	<channel #{about}>
		#{title_element(false)}
		#{link_element(false)}
		#{description_element(false)}
		#{image_element(false)}
#{items_element(false)}
		#{textinput_element(false)}
#{other_element(false, "\t\t")}
	</channel>
EOT
	      rv = @converter.convert(rv) if convert and @converter
  	    rv
			end

	    private
			def children
				[@image, @items, @textinput]
			end

			def _tags
				[
					[::RSS::URI, 'title'],
					[::RSS::URI, 'link'],
					[::RSS::URI, 'description'],
					[::RSS::URI, 'image'],
					[::RSS::URI, 'items'],
					[::RSS::URI, 'textinput'],
				].delete_if do |x|
					send(x[1]).nil?
				end
			end

			def _attrs
				[
					["about", true]
				]
			end
			
			class Image < Element
				
				include RSS10

				class << self
					
					def required_uri
						::RSS::URI
					end

				end

				[
					["resource", URI, true]
				].each do |name, uri, required|
					install_get_attribute(name, uri, required)
				end
			
				def initialize(resource=nil)
					super()
					@resource = resource
				end

				def to_s(convert=true)
					if @resource
						rv = %Q!<image #{PREFIX}:resource="#{h @resource}" />!
						rv = @converter.convert(rv) if convert and @converter
						rv
					else
						''
					end
				end

				private
				def _attrs
					[
						["resource", true]
					]
				end

			end

			class Textinput < Element
				
				include RSS10

				class << self
					
					def required_uri
						::RSS::URI
					end

				end

				[
					["resource", URI, true]
				].each do |name, uri, required|
					install_get_attribute(name, uri, required)
				end
			
				def initialize(resource=nil)
					super()
					@resource = resource
				end

				def to_s(convert=true)
					if @resource
						rv = %Q|<textinput #{PREFIX}:resource="#{h @resource}" />|
						rv = @converter.convert(rv) if convert and @converter
						rv
					else
						''
					end
				end
				
				private
				def _attrs
					[
						["resource", true],
					]
				end

			end
			
			class Items < Element

				include RSS10

				Seq = ::RSS::RDF::Seq
				class Seq
					unless const_defined?(:Li)
						Li = ::RSS::RDF::Li
					end
				end

				class << self
					
					def required_uri
						::RSS::URI
					end
					
				end

				install_have_child_element("Seq")
				
				install_must_call_validator('rdf', ::RSS::RDF::URI)
				
				def initialize(seq=Seq.new)
					super()
					@Seq = seq
				end
				
				def to_s(convert=true)
					<<-EOT
		<items>
#{Seq_element(convert)}
#{other_element(convert, "\t\t\t")}
		</items>
EOT
				end

				private
				def children
					[@Seq]
				end

				private
				def _tags
					rv = []
					rv << [URI, 'Seq'] unless @Seq.nil?
					rv
				end
				
				def rdf_validate(tags)
					_validate(tags, [["Seq", nil]])
				end

			end

		end

		class Image < Element

			include RSS10

			class << self
				
				def required_uri
					::RSS::URI
				end

			end
			
			[
				["about", URI, true]
			].each do |name, uri, required|
				install_get_attribute(name, uri, required)
			end

			%w(title url link).each do |x|
				install_text_element(x)
			end
		
			[
				['title', nil],
				['url', nil],
				['link', nil],
			].each do |tag, occurs|
				install_model(tag, occurs)
			end

			def initialize(about=nil)
				super()
				@about = about
			end

			def to_s(convert=true)
				about = ''
				about << %Q!#{PREFIX}:about="#{h @about}"! if @about
				rv = <<-EOT
	<image #{about}>
		#{title_element(false)}
		#{url_element(false)}
		#{link_element(false)}
#{other_element(false, "\t\t")}
	</image>
EOT
	      rv = @converter.convert(rv) if convert and @converter
	      rv
			end

			private
			def _tags
				[
					[::RSS::URI, 'title'],
					[::RSS::URI, 'url'],
					[::RSS::URI, 'link'],
				].delete_if do |x|
					send(x[1]).nil?
				end
			end

			def _attrs
				[
					["about", true],
				]
			end

		end

		class Item < Element

			include RSS10

			class << self

				def required_uri
					::RSS::URI
				end
				
			end

			[
				["about", URI, true]
			].each do |name, uri, required|
				install_get_attribute(name, uri, required)
			end

			%w(title link description).each do |x|
				install_text_element(x)
			end

			[
				["title", nil],
				["link", nil],
				["description", "?"],
			].each do |tag, occurs|
				install_model(tag, occurs)
			end

			def initialize(about=nil)
				super()
				@about = about
			end

			def to_s(convert=true)
				about = ''
				about << %Q!#{PREFIX}:about="#{h @about}"! if @about
				rv = <<-EOT
	<item #{about}>
		#{title_element(false)}
		#{link_element(false)}
		#{description_element(false)}
#{other_element(false, "\t\t")}
	</item>
EOT
	      rv = @converter.convert(rv) if convert and @converter
	      rv
			end
 
			private
			def _tags
				[
					[::RSS::URI, 'title'],
					[::RSS::URI, 'link'],
					[::RSS::URI, 'description'],
				].delete_if do |x|
					send(x[1]).nil?
				end
			end

			def _attrs
				[
					["about", true],
				]
			end

		end

		class Textinput < Element

			include RSS10

			class << self

				def required_uri
					::RSS::URI
				end

			end

			[
				["about", URI, true]
			].each do |name, uri, required|
				install_get_attribute(name, uri, required)
			end

			%w(title description name link).each do |x|
				install_text_element(x)
			end
		
			[
				["title", nil],
				["description", nil],
				["name", nil],
				["link", nil],
			].each do |tag, occurs|
				install_model(tag, occurs)
			end

			def initialize(about=nil)
				super()
				@about = about
			end

			def to_s(convert=true)
				about = ''
				about << %Q!#{PREFIX}:about="#{h @about}"! if @about
				rv = <<-EOT
	<textinput #{about}>
		#{title_element(false)}
		#{description_element(false)}
		#{name_element(false)}
		#{link_element(false)}
#{other_element(false, "\t\t")}
	</textinput>
EOT
	      rv = @converter.convert(rv) if convert and @converter
	      rv
			end

			private
			def _tags
				[
					[::RSS::URI, 'title'],
					[::RSS::URI, 'description'],
					[::RSS::URI, 'name'],
					[::RSS::URI, 'link'],
				].delete_if do |x|
					send(x[1]).nil?
				end
			end
			
			def _attrs
				[
					["about", true],
				]
			end

		end

	end

	RSS10::ELEMENTS.each do |x|
		BaseListener.install_get_text_element(x, URI, "#{x}=")
	end

	module ListenerMixin
		private
		def start_RDF(tag_name, prefix, attrs, ns)
			check_ns(tag_name, prefix, ns, RDF::URI)

			@rss = RDF.new(@version, @encoding, @standalone)
			@rss.do_validate = @do_validate
			@rss.xml_stylesheets = @xml_stylesheets
			@last_element = @rss
			@proc_stack.push Proc.new { |text, tags|
				@rss.validate_for_stream(tags) if @do_validate
			}
		end
	end

end
