#= require angular-scroll
#= require imagesloaded.min
#= require_self

app = angular.module 'gw', ['ngAnimate', 'smoothScroll']


# directives - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

app.directive 'focusMe', ['$timeout', ($timeout) ->
  restrict: 'A'
  scope:
    trigger: '@focusMe'
  link: (scope, element) ->
    scope.$watch 'trigger', (value) -> if value is 'true' then $timeout -> element[0].select()
    return
]

app.directive 'escFn', [ ->
  restrict: 'A'
  scope:
    fn: '=escFn'
  link: (scope, element) ->
    document.onkeyup = (e) -> if e.keyCode is 27 then scope.$apply -> scope.fn()
    return
]

app.directive 'scrollClass', ['$window', ($window) ->
  restrict: 'A'
  link: (scope, element) ->
    angular.element($window).bind 'scroll', () ->
      scope.scrolled = if @pageYOffset > 0 then true else false
      scope.$apply()
    return
]

app.directive 'lazyLoad', ['$window', ($window) ->
  restrict: 'AC'
  link: (scope, element, attribute) ->

    if attribute.background
      imgUrl = $window.getComputedStyle(element[0]).getPropertyValue 'background-image'
      imgUrl = imgUrl.substring(4,imgUrl.length-1)
    else
      imgUrl = angular.element(element).children()[0].src

    imgTag = new Image()
    imgTag.src = imgUrl
    imagesLoaded imgTag, -> angular.element(element).addClass 'loaded'
    return
]


# services - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

app.factory 'Util', [ ->
  {
    addLinks: (str) ->
      re = [
        '\\b((?:https?|ftp)://[^\\s"\'<>]+)\\b'
        '\\b(www\\.[^\\s"\'<>]+)\\b'
        '\\b(\\w[\\w.+-]*@[\\w.-]+\\.[a-z]{2,6})\\b'
        '#([a-z0-9]+)'
      ]
      re = new RegExp(re.join('|'), 'gi')
      str.replace re, (match, url, www, mail, twitler) ->
        if url then return '<a href="' + url + '" target="_blank">' + url + '</a>'
        if www then return '<a href="http://' + www + '" target="_blank">' + www + '</a>'
        if mail then return '<a href="mailto:' + mail + '" target="_blank">' + mail + '</a>'
        if twitler then return '<a href="https://twitter.com/search?q=%23' + twitler + '" target="_blank">#' + twitler + '</a>'
  }
]

app.service 'Overlay', [ ->
  {
    toggleOverlay: (str) ->
      @overlayOpen = !@overlayOpen
      @[str] = !@[str]

    closeOverlays: -> @overlayOpen = @twitterOverlay = @emailOverlay = false
  }
]


# controllers - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

app.controller 'OverlayController', ['$scope', 'Overlay', ($scope, Overlay) ->

  $scope.Overlay = Overlay
  $scope.escOverlays = -> Overlay.closeOverlays()
  $scope.toggleMenu = -> $scope.showMenu = !$scope.showMenu
  # $scope.adminShow = JSON.parse localStorage.getItem('admin')
]


app.controller 'TwitterController', [ '$scope', '$http', '$sce', 'Util', 'Overlay', ($scope, $http, $sce, Util, Overlay) ->

  $scope.trustAsHtml = $sce.trustAsHtml
  $scope.tweets = []
  $scope.hasTweets = -> $scope.tweets.length > 0

  $scope.$watch 'Overlay.twitterOverlay', (nV, oV) ->
    if nV is true && !$scope.hasTweets()
      $scope.loading = true
      $http.get '/assets/php/php-tweets/tweets.php'
      .success (result) ->
        $scope.tweets.push { text: Util.addLinks(tweet.text), image: tweet.user.profile_image_url } for tweet in result
      .error (error) ->
        console.log error
      .finally ->
        $scope.loading = false
]
