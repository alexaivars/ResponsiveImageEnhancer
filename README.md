ResponsiveImageEnhancer
=======================

## Introduction
Simple standalone javascript utility class to load alternative images deppending diferent css rules sett using mediaqueries.

This script is an addapted from Adam Bradley's https://github.com/adamdbradley/foresight.js but with less options and no intention of bandwidth guesing.

#### Example
<style>
  @media only screen and (max-width: 38em) {
    .jsImageEnhancer { 
      font-family: ' image-set( url({directory}{filename}.{ext}) 1x,
      url({directory}{filename}@2x.{ext}) 2x ) '; }
  }

  @media only screen and (min-width: 38em) and (max-width: 50em) {
    .jsImageEnhancer { font-family: ' image-set( url({directory}small/{filename}.{ext}) 1x,
    url({directory}small/{filename}@2x.{ext}) 2x ) '; }
  }

  @media only screen and (min-width: 50em) and (max-width: 64em) {
    .jsImageEnhancer { font-family: ' image-set( url({directory}medium/{filename}.{ext}) 1x,
    url({directory}medium/{filename}@2x.{ext}) 2x ) '; }
  }

  @media only screen and (min-width: 64em) {
    .jsImageEnhancer { font-family: ' image-set( url({directory}large/{filename}.{ext}) 1x,
    url({directory}large/{filename}@2x.{ext}) 2x ) '; }
  } 
</style>
<img data-src="path/to/my-image.jpg" class="jsImageEnhancer"/>
<noscript>
  <!-- Falback for non js users -->
  <img src="path/to/my-image.jpg"/>
</noscript>

<script>
  var iEnhancer = new ImageEnhancer();

  // make sure we also load images in ajax snipets
  $(document).ajaxComplete(function() { enhancer.load(); });
</script> 
