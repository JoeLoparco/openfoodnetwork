Darkswarm.controller "ProductsCtrl", ($scope, $filter, $rootScope, Products, OrderCycle, OrderCycleResource, FilterSelectorsService, Cart, Dereferencer, Taxons, Properties, currentHub, $timeout) ->
  $scope.Products = Products
  $scope.Cart = Cart
  $scope.query = ""
  $scope.taxonSelectors = FilterSelectorsService.createSelectors()
  $scope.propertySelectors = FilterSelectorsService.createSelectors()
  $scope.filtersActive = true
  $scope.page = 1
  $scope.per_page = 10
  $scope.order_cycle = OrderCycle.order_cycle
  $scope.supplied_taxons = {}
  $scope.supplied_properties = {}

  $rootScope.$on "orderCycleSelected", ->
    $scope.update_filters()
    $scope.clearAll()

  $scope.update_filters = ->
    order_cycle_id = OrderCycle.order_cycle.order_cycle_id

    return unless order_cycle_id

    $scope.supplied_taxons = {}
    $scope.supplied_properties = {}

    params = {
      id: order_cycle_id,
      distributor: currentHub.id
    }
    OrderCycleResource.taxons params, (data)=>
      data.map( (taxon) ->
        $scope.supplied_taxons[taxon.id] = Taxons.taxons_by_id[taxon.id]
      )
    OrderCycleResource.properties params, (data)=>
      data.map( (property) ->
        $scope.supplied_properties[property.id] = Properties.properties_by_id[property.id]
      )

  $scope.loadMore = ->
    if ($scope.page * $scope.per_page) <= Products.products.length
      $scope.loadMoreProducts()

  $scope.$watch 'query', (newValue, oldValue) -> $scope.loadProducts() if newValue != oldValue
  $scope.$watchCollection 'activeTaxons', (newValue, oldValue) -> $scope.loadProducts() if newValue != oldValue
  $scope.$watchCollection 'activeProperties', (newValue, oldValue) -> $scope.loadProducts() if newValue != oldValue

  $scope.loadProducts = ->
    $scope.page = 1
    params = {
      id: $scope.order_cycle.order_cycle_id,
      page: $scope.page,
      per_page: $scope.per_page,
      'q[name_or_meta_keywords_or_supplier_name_cont]': $scope.query,
      'q[properites_in_any][]': $scope.activeProperties,
      'q[primary_taxon_id_in_any][]': $scope.activeTaxons
    }
    Products.update(params)

  $scope.loadMoreProducts = ->
    params = {
      id: $scope.order_cycle.order_cycle_id,
      page: $scope.page + 1,
      per_page: $scope.per_page,
      'q[name_or_meta_keywords_or_supplier_name_cont]': $scope.query,
      'q[properites_in_any][]': $scope.activeProperties,
      'q[primary_taxon_id_in_any][]': $scope.activeTaxons
    }
    Products.update(params, true)
    $scope.page += 1

  $scope.searchKeypress = (e)->
    code = e.keyCode || e.which
    if code == 13
      e.preventDefault()

  $scope.appliedTaxonsList = ->
    $scope.activeTaxons.map( (taxon_id) ->
      Taxons.taxons_by_id[taxon_id].name
    ).join(" #{t('products_or')} ") if $scope.activeTaxons?

  $scope.appliedPropertiesList = ->
    $scope.activeProperties.map( (property_id) ->
      Properties.properties_by_id[property_id].name
    ).join(" #{t('products_or')} ") if $scope.activeProperties?

  $scope.clearAll = ->
    $scope.query = ""
    $scope.taxonSelectors.clearAll()
    $scope.propertySelectors.clearAll()
