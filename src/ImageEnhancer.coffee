###
# Copyright © 2012 Alexander Aivars, Kramgo AB
# 
# You may do anything with this work that copyright law would normally
# restrict, so long as you retain the above notice(s) and this license
# in all redistributed copies and derived works.  There is no warranty.
#
#
#
# Class: ImageEnhancer
#
# Simple util class to load alternative images for diferent mediaqueries.
# addapted from Adam Bradley's https://github.com/adamdbradley/foresight.js but
# with less options and no intention of bandwidth guesing.
#
# Example: 
#
# <style>
#   @media only screen and (max-width: 38em) {
#     .jsImageEnhancer { 
#       font-family: ' image-set( url({directory}{filename}.{ext}) 1x,
#       url({directory}{filename}@2x.{ext}) 2x ) '; }
#   }
#
#   @media only screen and (min-width: 38em) and (max-width: 50em) {
#     .jsImageEnhancer { font-family: ' image-set( url({directory}small/{filename}.{ext}) 1x,
#     url({directory}small/{filename}@2x.{ext}) 2x ) '; }
#   }
#
#   @media only screen and (min-width: 50em) and (max-width: 64em) {
#     .jsImageEnhancer { font-family: ' image-set( url({directory}medium/{filename}.{ext}) 1x,
#     url({directory}medium/{filename}@2x.{ext}) 2x ) '; }
#   }
#
#   @media only screen and (min-width: 64em) {
#     .jsImageEnhancer { font-family: ' image-set( url({directory}large/{filename}.{ext}) 1x,
#     url({directory}large/{filename}@2x.{ext}) 2x ) '; }
#   } 
# </style>
# <img data-src="path/to/my-image.jpg" class="jsImageEnhancer"/>
# <noscript>
#   <!-- Falback for non js users -->
#   <img src="path/to/my-image.jpg"/>
# </noscript>
#
# <script>
#   var iEnhancer = new ImageEnhancer();
#
#   // make sure we also load images in ajax snipets
#   $(document).ajaxComplete(function() { enhancer.load(); });
# </script> 
#
################################################################################



class ImageEnhancer
  
  images: []
  
  isRetina: false
  isMobile: false
  idReloadTimeout: null
  imageClass: 'jsImageEnhancer'
  imageSetRegex : /url\((?:([a-zA-Z-_0-9{}\?=&\\/.:\s@]+)|([a-zA-Z-_0-9{}\?=&\\/.:\s@]+)\|([a-zA-Z-_0-9{}\?=&\\/.:\s@]+))\)/g

  cleanRegex: /[\t\r\n]/g
  uriTags: [ 'src', 'protocol', 'host', 'port', 'directory', 'file', 'filename', 'ext', 'query']

  constructor: () ->
    @isRetina = window.devicePixelRatio >= 1.5 ? true : false
    @isMobile = navigator.userAgent.match(/(iPhone|iPod|iPad|Android|BlackBerry|Windows Phone|ZuneWP7)/)
    @addWindowResizeEvent()
    @reloadExecute()

    return
  
  initImages: () ->
    
    @images = []
    for img in document.images
      if img.initalized || @hasClass( img, @imageClass )
        # unless img.isEnhancedX
         
        imageSet =  @getComputedStyleValue( img, 'font-family', 'fontFamily' )
        
        # Only update if a media query has changed the css rules 
        unless img.uriData
          img.uri = @getDataAttribute( img, 'src' )
          img.uriData = parseUri img.uri

        unless imageSet == img.imageSet
          img.initalized = true
          img.imageSet = imageSet
          @parseImageSet(img,imageSet)
                  
        @images.push img
    return

  loadImages: () ->
    for img in @images
      # loop through all the possible format keys and 
      # replace them with their respective value for this image
      if img.rules.length > 1 && @isRetina
        src = img.rules[1]['template']
      else
        src = img.rules[0]['template']
       
      for tag, i in @uriTags
        src = src.replace("{#{tag}}", img.uriData[tag])

      img.src = src

    return

  parseImageSet: ( element , imageSet ) ->
    # clean and split image-set rules
    imageSet = imageSet.split( 'image-set(' )[ 1 ].split( ',' )
    
    
    element.rules = []

    for text in imageSet
      rule =
        text: text

      # get the scale factor 
      if text.indexOf(" 1.5x") > -1
        rule['scale'] = 1.5
      else if text.indexOf(" 2x") > -1
        rule['scale'] = 2
      else
        # We treat all unsoported scales as 1 
        # In the future we might default to nearast supported scale
        rule['scale'] = 1
      
      while match = @imageSetRegex.exec( rule.text )
        rule['template'] = match[1]
      
      element.rules.push(rule)
    

    element.rules.sort(@sortImageSet)


    return

  sortImageSet: (a,b) ->
    # image set items with a higher weight will sort at the beginning of the array
    return 1  if a.scale > b.scale
    return -1  if a.scale < b.scale
    0

  addWindowResizeEvent: ->
    # attach the foresight.reload event that executes when the window resizes
    if window.addEventListener
      window.addEventListener "resize", ( (event) => @windowResized(event) ), false
    else if window.attachEvent
      window.attachEvent "onresize", (event) => @windowResized(event)

  windowResized: (event) ->
    
    @reload()
  

  reloadExecute: () ->
    @initImages()
    @loadImages()
    return
  
  # DOM HELPER METHODS
  hasClass: ( element, selector ) ->
    className = " " + selector + " "
    return true  if element.nodeType is 1 and (" " + element.className + " ").replace(@cleanRegex, " ").indexOf(className) > -1
    false

  getDataAttribute: (img, attribute, getInt, value) ->
    value = img.getAttribute("data-" + attribute)
    if getInt
      return parseInt(value, 10)  unless isNaN(value)
      return 0
    return value
  
  getComputedStyleValue: ( element, cssProperty, jsReference ) ->
    # get the computed style value for this element
    jsReference = cssProperty  unless jsReference
    return (if element.currentStyle then element.currentStyle[jsReference] else document.defaultView.getComputedStyle(element, null).getPropertyValue(cssProperty))

  # PUBLIC API METHODS 
  reload: () ->
    # public method available if the DOM changes since the initial load (like an Ajax load)
    # Uses a timeout so it can govern how many times the reload executes without goin nuts
    window.clearTimeout @idReloadTimeout
    @idReloadTimeout = window.setTimeout( ( () => @reloadExecute() ), 250 )
    return

## Because we are lazy and like to console log without other browsers exploding
window.console ?=
  log:->
    return

# parseUri 1.2.2
# (c) Steven Levithan <stevenlevithan.com>
# MIT License
# Modified by Alexander Aivars for ImageEnhancer
# parseUri 1.2.2
# (c) Steven Levithan <stevenlevithan.com>
# MIT License
parseUri = (str) ->
  o = parseUri.options
  m = o.parser[(if o.strictMode then "strict" else "loose")].exec(str)
  uri = {}
  i = 14
  uri[o.key[i]] = m[i] or ""  while i--
  uri[o.q.name] = {}
  uri[o.key[12]].replace o.q.parser, ($0, $1, $2) ->
    uri[o.q.name][$1] = $2  if $1

  split = uri.file.split(".")
  uri['filename'] = split[0]
  uri['ext'] = ((if split.length > 1 then split[split.length - 1] else ""))

  uri

parseUri.options =
  strictMode: true
  key: ["source", "protocol", "authority", "userInfo", "user", "password", "host", "port", "relative", "path", "directory", "file", "query", "anchor"]
  q:
    name: "queryKey"
    parser: /(?:^|&)([^&=]*)=?([^&]*)/g

  parser:
    strict: /^(?:([^:\/?#]+):)?(?:\/\/((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?))?((((?:[^?#\/]*\/)*)([^?#]*))(?:\?([^#]*))?(?:#(.*))?)/
    loose: /^(?:(?![^:@]+:[^:@\/]*@)([^:\/?#.]+):)?(?:\/\/)?((?:(([^:@]*)(?::([^:@]*))?)?@)?([^:\/?#]*)(?::(\d*))?)(((\/(?:[^?#](?![^?#\/]*\.[^?#\/.]+(?:[?#]|$)))*\/?)?([^?#\/]*))(?:\?([^#]*))?(?:#(.*))?)/



window.ImageEnhancer = ImageEnhancer
