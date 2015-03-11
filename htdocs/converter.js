angular.module('Converter',['ui.bootstrap'])
.controller('MainController',function($scope) {
    $scope.baseURL = window.location.href.split('?')[0].split('#')[0];
    //$scope.outputtype = "application/json";
    $scope.to = "json-ld";
})
.directive('formatListFrom',['$http',function($http) {
    return {
        restrict: 'A',
        scope: { 
            api: '@formatListFrom'
        },
        templateUrl: 'formats.html',
        link: function link(scope, element, attr) {
            scope.$watch('api',function(value) {
                $http.get(value).success(
                    function(data) {
                        scope.formats = data;
                    }
                );
            });
        }
    }
}]);
