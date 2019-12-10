# Elm Bootstrap Gallery

[![Elm Bootstrap Build Status](https://travis-ci.org/prikhi/bootstrap-gallery.svg?branch=master)](https://travis-ci.org/prikhi/bootstrap-gallery)


This package allows you to pop-open a model gallery for flipping through images
or displaying a single image in a lightbox.

It uses style animations to fade the modal in & out and to fade between images.
Clickable elements allow viewers to scroll through images or dismiss the modal.

The CSS classes used in the rendering function tie this to Bootstrap v4. In the
future, this may be made more customizable and CSS-framework agnostic.

It was originally developed for the [Foundation for Intentional Community's
Wordpress Theme][fic-theme] and was extracted from that repository.


## Contribute

Contributions, feature requests, & bug reports are always welcome!


There is an `.nvmrc` & `package.json` in this directory, so you can run `nvm
use && npm i` to get all the development tools installed.

Run `npx edp` to launch a server for previewing the documentation and `npx
elm-analyse -s` to launch a server for linting the code.


## TODO

These are things that weren't necessary for the FIC gallery modal, but would be
nice for other library consumers:

* Store list in model? Currently don't have it so thumbnails & next/prev
  could have different sets of images.
* Hide next/prev buttons on single item list.
* Dim current & show spinner while waiting for next/prev image to load
    * Do we stack the current and next image on top of each other, with a
      spinner in between?
* Esc & arrow keys to close/navigate
    * It seems like this'd require subscriptions to ports that bind the onkeyup
      events to the document. Which means some documentation & example code for
      eventual package.
    * Or maybe we could focus part of the modal when it opens so we can catch
      events on there?
* Allow showing row of thumbnails below image or bottom of screen.
* Example app containing single image lightbox & gallery of images.

## License

BSD-3-Clause, exceptions possible.

[fic-theme]: https://github.com/Foundation-For-Intentional-Community/Wordpress-Theme
