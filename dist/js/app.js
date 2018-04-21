App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',

  init: function() {
    // Load pets.
    // $.getJSON('../pets.json', function(data) {
    //   var petsRow = $('#petsRow');
    //   var petTemplate = $('#petTemplate');

    //   for (i = 0; i < data.length; i ++) {
    //     petTemplate.find('.panel-title').text(data[i].name);
    //     petTemplate.find('img').attr('src', data[i].picture);
    //     petTemplate.find('.pet-breed').text(data[i].breed);
    //     petTemplate.find('.pet-age').text(data[i].age);
    //     petTemplate.find('.pet-location').text(data[i].location);
    //     petTemplate.find('.btn-adopt').attr('data-id', data[i].id);

    //     petsRow.append(petTemplate.html());
    //   }
    // });

    return App.initWeb3();
  },

  initWeb3: function() {
    /*
     * Replace me...
     */

     if (typeof web3 !== 'undefined') {
      // If a web3 instance is already provided by Meta Mask.
      App.web3Provider = web3.currentProvider;
      web3 = new Web3(web3.currentProvider);
    } else {
      // Specify default instance if no web3 instance provided
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },

  initContract: function() {
    /*
     * Replace me...
     */



     $.getJSON("Logic.json", function(logic) {
      // Instantiate a new truffle contract from the artifact
      App.contracts.Logic = TruffleContract(logic);
      // Connect provider to interact with contract
      App.contracts.Logic.setProvider(App.web3Provider);

      App.listenForEvents();

      return App.render();
    });



    // return App.bindEvents();
  },



  listenForEvents: function() {
    App.contracts.Logic.deployed().then(function(instance) {
    //   // Restart Chrome if you are unable to receive this event
    //   // This is a known issue with Metamask
    //   // https://github.com/MetaMask/metamask-extension/issues/2393
      instance.stateChanged({}, {
        fromBlock: 'latest',
        toBlock: 'latest'
      }).watch(function(error, event) {
        if(event.args.user == App.account){
          App.render();   
        }
        console.log("event startgame triggered", event)
        // Reload when a new vote is recorded
      });
    });
  },

  hideEveryThing : function(){
    var norm  = $("#norm");
    var accept = $("#accept");
    var inGame = $("#inGame");
    var hiding = $("#hideDiv");
    norm.hide();
    accept.hide();
    inGame.hide();
    hiding.hide();
  },
  render: function() {
    var norm  = $("#norm");
    var accept = $("#accept");
    var inGame = $("#inGame");
    var hiding = $("#hideDiv");
    App.hideEveryThing();
    // Load account data
    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
      }
    });

    $("#temp").html(App.theOtherPlayer);

    var norm = $("#norm");
    var accept = $("#accept");
    var inGame = $("#inGame");
    var instanceNow;
    App.contracts.Logic.deployed().then(function(instance){
      

      instance.getScoreTemp().then(function(tempRes){
        $("#scoreBegin").empty();
        $("#scoreBegin").append('momentory score : '+tempRes.toNumber());
      });


      instance.getScoreFinal().then(function(FinalRes){
        $("#scoreFinal").empty();
        $("#scoreFinal").append('final score : '+FinalRes.toNumber());
      });


      prom1 = instance.getState().then(function(value){
        console.log(value.toNumber());
        

        if(value.toNumber()==0){
            App.hideEveryThing();
            norm.show();
        }


        if(value.toNumber()==1){
          App.hideEveryThing();
          hiding.show();
          hiding.empty();
          hiding.append("<h3>you are waaaittiiing :D</h3>");
          hiding.show();
        }


        if(value.toNumber()==3){
          App.hideEveryThing();
          instance.getOtherPlayer().then(function(other){
            accept.show();
            App.whoAsked = other;
            $("#messageAccept").html(other+ "   has asked you to play :D , will you accept ?<br>");   
          });
        }

        if(value.toNumber()==2){
          App.hideEveryThing();
          inGame.show();
          instance.print().then(function(result){
            instance.getWhichPlayerItIs().then(function(num){
              console.log(result[0][0].toNumber());
              for(var i = 0 ;i < 6 ;  i ++){
                for(var j=0 ;j<6 ; j ++){
                  var char;
                  if(num.toNumber()==result[i][j].toNumber()){
                    char = "  x  ";
                  }
                  else if(result[i][j].toNumber()==0){
                    char = "  _  ";
                  }else {
                    char = "  o  ";
                  }
                  $("#id_row"+(i+1)+"col_"+(j+1)).text(char);
                }
              }
            });
          });
        }

      });
    });

    




  },
  
  sendReq : function(event){
              App.contracts.Logic.deployed().then(function(instance){
                console.log($("#toWho").val())
                return instance.startGameFunc($("#toWho").val());
              }).then(function(result){
                $("#accountAddress").hide();
              }).catch(function(error){
                console.warn(error);
              });
  },

  noFunc : function(event){
        
        App.contracts.Logic.deployed().then(function(instance){
          instance.getOtherPlayer().then(function(theOther){
            instance.reject(theOther,{gas:100000});
            // App.render();
          });
        });
  },

  yesFunc : function(event){
        App.contracts.Logic.deployed().then(function(instance){
          instance.getOtherPlayer().then(function(theOther){
            console.log(theOther);
            instance.accept(theOther);
            // App.render();
          });
        });
  },
  onReload : function(event){
    console.log("dis");
  },
  makeAction : function(evnet){
    var x = parseInt($("#x").val());
    var y = parseInt($("#y").val());
    if(isNaN(x)){
      x=-1;
    }
      if(!isNaN(y)){
        if(((x==-1)||(x>=1&&x<=6))&&y>=1&&y<=6){
          console.log(x);
          console.log(y);
          App.contracts.Logic.deployed().then(function(instance){
            if(x==-1){
              instance.noramlAction(y);
            }else{
              instance.useCheat(x,y);
            }
          }).catch(function(error){
            console.warn(error);
          });
        }
      }
  },


}
  

$(function() {
  $(window).load(function() {
    App.init();
  });
});
