from html.parser import HTMLParser

class HTMLCleaner(HTMLParser):
    def __init__(self, *args, **kwargs):
        super(HTMLCleaner, self).__init__(*args, **kwargs)
        self.tag_stack = []
        self.data_list = []
        self.hasdata = False

    def handle_starttag(self, tag, attrs):
        self.tag_stack.append(tag)
        self.hasdata = False
        print("Encountered a start tag:", tag,self.hasdata )

    def handle_endtag(self, tag):
        pop_tag = self.tag_stack.pop()

        if pop_tag == tag and self.hasdata == False:
            self.data_list.append('')

        print("Encountered an end tag :", tag,self.hasdata )

    def handle_data(self, data):
        self.hasdata = True
        print (data,self.hasdata)
        self.data_list.append(data)

parser = HTMLCleaner()
parser.feed('<html><head><title>Test</title></head>'
'<body><h1>Parse me!</h1><table><tr><td> </td><td>a</td><td>b</td></table></body></html>')

print ('----------------------------------------------------------------')
print (parser.data_list)