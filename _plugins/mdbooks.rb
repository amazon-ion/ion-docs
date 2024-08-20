# A simple Jekyll generator plugin that will run mdbook
# See https://jekyllrb.com/docs/plugins/generators/ for info about generators
module IonDocs
  class MdBookGenerator < Jekyll::Generator
    safe true
    def generate(site)
      # If we have more books, either loop through them, or add a new line for each
      system( "mdbook build ./_books/ion-1-1 -d ./../../_site/books/ion-1-1" )
    end
  end
end
