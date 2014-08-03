module Jekyll
    class Page
        # The generated relative url of this page. e.g. /about.html.
        #
        # Returns the String url.
        alias orig_url url
        def url
            theurl = URL.new({
                             :template => template,
                             :placeholders => url_placeholders,
                             :permalink => permalink
                             }).to_s
                             
                             # Get the language of the page from the name of the post
                             languageFromFile = GetLanguage.get_language(theurl)
                             if(languageFromFile)
                                 self.data = GetLanguage.merge_data(self.data, languageFromFile, true)
                                 theurl.gsub!(".#{languageFromFile}",'')
                             end
                             
                             language = self.data['language']
                             
                             if(language)
                                 theurl.sub!("/#{language}/",'/')
                                 theurl = "/#{language}#{theurl}"
                             end
                             @url = theurl
        end
        
        alias orig_dir dir
        def dir
            directory = orig_dir
            language = self.data['language']
            if(language)
                directory.sub!("/#{language}",'/')
            end
            return directory
        end
    end
    class Post
        # The generated relative url of this page. e.g. /about.html.
        #
        # Returns the String url.
        
        alias orig_init initialize
        def initialize(site, base, dir, name)
            orig_init(site, base, dir, name)
            languageFromFile = GetLanguage.get_language(path)
            if(languageFromFile)
                self.data = GetLanguage.merge_data(self.data, languageFromFile, true)
            end
        end
        def url
            theurl = URL.new({
                             :template => template,
                             :placeholders => url_placeholders,
                             :permalink => permalink
                             }).to_s
                             
                             language = self.data['language']
                             #puts language
                             theurl.gsub!(".#{language}",'')
                             theurl = "/#{language}#{theurl}"
                             @url = theurl
        end
    end
    
    class LanguagePostGenerator < Generator
        priority :highest
        def generate(site)
            site.posts.each { |post|
                languages = site.config['languages'].dup
                if (post.data['multilingual'] == nil)
                    puts "found post #{post.url} without language"
                    defined_language=post.data['language']
                    if(!defined_language)
                        defined_language = languages[0]
                    end
                    post.data = GetLanguage.merge_data(post.data, defined_language, false)
                    languages.delete(defined_language)
                    
                    
                    languages.each do |lang|
                        puts "Generating post for #{lang}"
                        newpost = post.dup
                        newpost.data = Jekyll::Utils.deep_merge_hashes(newpost.data,{
                                                                       'language' => lang,
                                                                       'multilingual' => false,
                                                                       'mainlanguage' => defined_language,
                                                                       'title' => "#{newpost.data['title']}"
                                                                       })
                                                                       site.posts<<newpost
                    end
                end
            }
        end
        
    end
    class LanguagePageGenerator < Generator
        priority :lowest
        def generate(site)
            
            site.pages.each { |page|
                languages = site.config['languages'].dup
                if (page.data['multilingual'] == nil)
                    url = page.url
                    puts "found page #{url} without language"
                    defined_language=page.data['language']
                    if(!defined_language)
                        defined_language = languages[0]
                        puts "  Setting default language #{defined_language}"
                        page.data = GetLanguage.merge_data(page.data, defined_language, false)
                    end
                    languages.delete(defined_language)
                    
                    
                    languages.each do |lang|
                        puts "  Generating page for #{lang}"
                        newpage = page.dup
                        newpage.data = Jekyll::Utils.deep_merge_hashes(newpage.data,{
                                                                       'language' => lang,
                                                                       'multilingual' => false,
                                                                       'mainlanguage' => defined_language,
                                                                       'title' => "#{newpage.data['title']}"
                                                                       })
                                                                       site.pages<<newpage
                    end
                end
            }
        end
    end
    
    module LanguagePostIndicatorFilter
        def language_flag(post)
            if(post != nil && isNonMultilingualPostInDifferentLanguage(post))
                lang = post['mainlanguage']
                return "<img src='#{@context.registers[:site].baseurl}/images/#{ lang }.png' alt='#{ lang }' class='flag'/>"
            end
            ""
        end
        def language_text(post)
            if(post != nil && isNonMultilingualPostInDifferentLanguage(post))
                return " (#{ post['mainlanguage']})"
            end
            ""
        end
        
        def isNonMultilingualPostInDifferentLanguage(post)
            return post['multilingual'] != true && (post['language'] != @context.registers[:page]['language'] || post['mainlanguage'] != nil)
        end
    end
    
    class LanguageArrayFilter < Liquid::Tag
        Syntax = /(\w+[.]?\w+)\s+(\w+)\s+(\w+[.]?\w+)/o
        
        def initialize(tag_name, markup, tokens)
            if markup =~ Syntax
                @collection_name = $1
                @taget_collection_name = $2
                @taget_language = $3
                else
                raise SyntaxError.new("Syntax Error in 'language_array' - Valid syntax: random [source] [var] [language]")
            end
            
            super
        end
        
        def render(context)
            collection = context[@collection_name]
            if collection
                filtered_collection = collection.select { |post|
                    post.data['language'] == nil || post.data['language'] == context[@taget_language]
                }
                context[@taget_collection_name] = filtered_collection
            else
                context[@taget_collection_name] = collection
            end
            return
        end
    end
    
end

class GetLanguage
    # Get Language
    def self.get_language(url)
    lang=url.match(/.*\.([a-z]{2})(?:\.markdown|\.md|\.html)?(?:\/)?$/)
    if(lang && lang[1] != "md")
    return lang[1]
end
return nil
end

# Merge the data with the language values.
def self.merge_data(data, language, multilingual)
if (language)
    data = Jekyll::Utils.deep_merge_hashes(data,{
                                           'language' => language,
                                           'multilingual' => multilingual,
                                           })
end
return data
end
end

Liquid::Template.register_filter(Jekyll::LanguagePostIndicatorFilter)
Liquid::Template.register_tag('language_array', Jekyll::LanguageArrayFilter)