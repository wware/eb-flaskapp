var CryptoSynchronizer = function(
    plainSetter, plainGetter, cipherSetter, cipherGetter,
    keyGetter, threeStrikes) {

    var numFailedDecryptions = 0;
    var pub = {};
    if (!threeStrikes) {
        threeStrikes = function() {};
    }

    pub.encrypt = function() {
        var x = plainGetter();
        var key = keyGetter();
        var y = Rijndael.Encrypt(x, key);
        numFailedDecryptions = 0;
        cipherSetter(y);
    };

    pub.decrypt = function() {
        var x = cipherGetter();
        var key = keyGetter();
        var y = Rijndael.Decrypt(x, key);
        if (y === null) {
            numFailedDecryptions++;
            if (threeStrikes && numFailedDecryptions == 3) {
                threeStrikes();
                numFailedDecryptions = 0;
                return;
            }
        }
        plainSetter(y);
    };

    return pub;
};

var myApp = angular.module('myApp', []);

myApp.controller('PasswordSafeController', ['$scope',
    function($scope) {
        var pinLockedKey;
        var keyLockedContent;
        $scope.key = "CAFEBABECAFEBABECAFEBABECAFEBABE";
        $scope.pin = "1234";
        var csyncKey = CryptoSynchronizer(
            function(x) {
                $scope.key = x;
            },
            function() {
                return $scope.key;
            },
            function(x) {
                pinLockedKey = x;
            },
            function() {
                return pinLockedKey;
            },
            function() {
                var pin = $scope.pin;
                while (pin.length < 16)
                    pin += "\0";
                return pin;
            });
        var csyncContent = CryptoSynchronizer(
            function(x) {
                $scope.pin = "";
                $scope.secrets = x;
            },
            function() {
                return $scope.secrets;
            },
            function(x) {
                keyLockedContent = x;
            },
            function() {
                return keyLockedContent;
            },
            function() {
                return $scope.key;
            });
        csyncKey.encrypt();
        $scope.secrets = "Call me Ishmael. There was this whale. " +
            "Then everything went all to hell. The End.";
        csyncContent.encrypt();
        $scope.key = "";
        $scope.secrets = "";
        $scope.unlock = function() {
            csyncKey.decrypt();
            csyncContent.decrypt();
        };
        $scope.clear = function() {
            $scope.key = "";
            $scope.secrets = "";
        };
        $scope.save = function() {
            csyncKey.encrypt();
            csyncContent.encrypt();
            $scope.key = "";
            $scope.secrets = "";
        };
        $scope.$watch(
            "existing",
            function() {
                $scope.showkey = $scope.existing;
                // OR show the key if it exists in localStorage
            });
        $scope.existing = false;
        $scope.showkey = false;
        $scope.toggle = function(x) {
            var img = x.target;
            var vis = $(".vis_" + img.id);
            if (vis) {
                if (vis.hasClass("closed")) {
                    vis.removeClass("closed");
                    vis.addClass("open");
                    img.src = "/opened.gif";
                } else {
                    vis.addClass("closed");
                    vis.removeClass("open");
                    img.src = "/closed.gif";
                    if (vis.hasClass("blank-stuff")) {
                        $scope.pin = "";
                        $scope.key = "";
                        $scope.secrets = "";
                    }
                }
            }
        };
    }
]);
