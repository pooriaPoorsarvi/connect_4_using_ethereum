pragma solidity ^0.4.19;
/**
 * The Logic contract does this and that...
 */
contract Logic {




	

	mapping (address => uint256) scoringBegining;
	mapping (address => uint256) scoreFinal;
	mapping (address => uint256) lastTime;
	
	
	mapping (address => uint256) state;
	// state == 0 idle , state == 1 waiting , state == 2 in game 3 if someOneHasAskedHim
	mapping (address=>uint256 [6][6]) gameState;
    // 	at first I wanted map to be on the client side but that way there is no way of verifying the map :D
    mapping (address=>bool) allowedToMakeAction;
    mapping (address=>address) playingWithWho;
    // if the player is not playing with anyone this will store who has asked you to play with them
    
    mapping(address=>uint256) whichPlayerItIs;
    // we need this in order to know which player made which action





	event madeAction(address indexed  actor, int256 indexed  x, uint256 indexed  y);
	event startGame(address   started, address   player2);
	// the first arg in the next two events is that so there would be no confusion for players
	event acceptGame(address indexed  acceptedWhom, address indexed  acceptor);
	event rejected(address indexed  whoWasRejected, address indexed  whoRejected);
	
	event stateChanged(address indexed user);

	function Logic () {

	}
	
	
	function geAllowed() constant returns (bool){
	    return allowedToMakeAction[msg.sender];
	}

    function getState() constant returns(uint256) {
        return state[msg.sender];
    }
    function getWhichPlayerItIs() constant returns (uint256) {
    	return whichPlayerItIs[msg.sender];
    }
    function getOtherPlayer() constant returns(address){
        return playingWithWho[msg.sender];
    }
    
    
    function getScoreTemp() public constant returns (uint256){
        return scoringBegining[msg.sender];
    }
    
    function getScoreFinal() public constant returns (uint256){
        return scoreFinal[msg.sender];
    }

	function startGameFunc (address _player2) public returns (bool) {
		
		if(state[_player2]!=0){
		    return false;
		}
		
		uint256 time = block.timestamp ; 
		if(lastTime[msg.sender]-time>3600){
			lastTime[msg.sender] = time ;
			scoreFinal[msg.sender] += scoringBegining[msg.sender] ;
			scoringBegining[msg.sender] = 0 ;
		}
		
		state[msg.sender]=1;
		state[_player2]=3;
		playingWithWho[_player2]=msg.sender;

		
		stateChanged(msg.sender);
		stateChanged(_player2);
		

		return true;
	}


	function accept (address _player1) public {
		uint256 time = block.timestamp ; 
		if(lastTime[msg.sender]-time>3600){
			lastTime[msg.sender] = time ;
			scoreFinal[msg.sender] += scoringBegining[msg.sender] ;
			scoringBegining[msg.sender] = 0 ;
		}
		
		state[msg.sender]=2;
		state[_player1]=2;
		
		allowedToMakeAction[_player1] = true;
		
		playingWithWho[_player1] = msg.sender;
		playingWithWho[msg.sender] = _player1;
		
		
		whichPlayerItIs[_player1]=1;
		whichPlayerItIs[msg.sender]=2;
		
		stateChanged(_player1);
		stateChanged(msg.sender);

	}

	function reject (address _player1) public {


		state[msg.sender]=0;
		state[_player1]=0;

		stateChanged(msg.sender);
		stateChanged(_player1);
	}
	
	
	
    function print() constant returns(uint256 [6][6]){
        uint256 [6][6] a=gameState[msg.sender];
        return a;
    }

    // the next function is so we can use require and there won't be alot of loss on the gas
    function checkIfHasEmpty(uint y) constant returns (bool){
        uint256 [6][6] a=gameState[msg.sender];
		
		for(uint256 i=5;i>=0;i--){
		    uint256 s = a[i][y-1];
		    if(s==0){
		        s = whichPlayerItIs[msg.sender];
		        return true;
		    }
		    
		    
		  // to end the loop no matter what :D
		    if(i==0){
		        break;
		    }
		}
		
		return false;
    }
    
    
    
    
	function noramlAction (uint y) public {

		require (y>=1 && y <= 6);
		
		require(allowedToMakeAction[msg.sender]);
		
		
		require(checkIfHasEmpty(y));
		
		uint256 [6][6] a=gameState[msg.sender];
		uint256 [6][6] b=gameState[playingWithWho[msg.sender]];
		
		for(uint256 i=5;i>=0;i--){
		    
		    if(a[i][y-1]==0){
		        
		        a[i][y-1] = whichPlayerItIs[msg.sender];
                b[i][y-1] = whichPlayerItIs[msg.sender]; 
		        
		        break;
		    }
		    
		    
		  // to end the loop no matter what :D
		    if(i==0){
		        break;
		    }
		}
		
		allowedToMakeAction[msg.sender] = false;
		allowedToMakeAction[playingWithWho[msg.sender]]=true;
		
		
		if(endGame()){
		    state[msg.sender]=0;
		    state[playingWithWho[msg.sender]]=0;
		    scoringBegining[msg.sender] += 5;
		    
		    for(uint i1=0;i1<6;i1++){
		        for(uint j1=0;j1<6;j1++){
		            a[i1][j1]=0;
		            b[i1][j1]=0;
		        }
		    }
		    
		}
		
		stateChanged(msg.sender);
		stateChanged(playingWithWho[msg.sender]);
	}
	

	function useCheat (int256 x, uint256 y)  public {

		// this was my first implimentation but I guess the other way would spend less gas
		// if(scoringBegining[msg.sender]>=10){
		// 	scoringBegining[msg.sender]-=10;
		// 	madeAction(x,y);
		// 	return true;
		// }
		// return false;



		require (x>=1 && x<=6);

		require (y>=1 && y<=6);
		
		require (allowedToMakeAction[msg.sender]);
		
		
		
		
		require (scoringBegining[msg.sender] >= 10);
		
		uint256[6][6] a =  gameState[msg.sender];
		uint256[6][6] b =  gameState[playingWithWho[msg.sender]];
		require(a[uint256(x)-1][y-1]==0);
		
		a[uint256(x)-1][y-1] = whichPlayerItIs[msg.sender];
		b[uint256(x)-1][y-1] = whichPlayerItIs[msg.sender];
		
		
		allowedToMakeAction[msg.sender]=false;
		allowedToMakeAction[playingWithWho[msg.sender]]=true;
		
		
		
		if(endGame()){
		    state[msg.sender]=0;
		    state[playingWithWho[msg.sender]]=0;
		    scoringBegining[msg.sender] += 5;
		    for(uint i=0;i<6;i++){
		        for(uint j=0;j<6;j++){
		            a[i][j]=0;
		            b[i][j]=0;
		        }
		    }
		    
		}
		
		stateChanged(msg.sender);
		stateChanged(playingWithWho[msg.sender]);
		

	}
	
	
	function exit() public {
	    state[msg.sender]=0;
	    state[playingWithWho[msg.sender]]=0;
	    
	    stateChanged(msg.sender);
		stateChanged(playingWithWho[msg.sender]);
	}
	
	
	function endGame() constant public returns (bool) {
	    uint256 num = whichPlayerItIs[msg.sender];
	    uint256 [6][6] a = gameState[msg.sender];
	    for(uint i=0;i<6;i++){
	        for(uint j=0;j<6;j++){
	            
	            if(i>=3){
	                   if(a[i][j]==a[i-1][j]&&a[i-1][j]==a[i-2][j]&&a[i-2][j]==a[i-3][j]&&a[i-1][j]==num){
	                       return true;
	                   }
	            }
	            if(i<=2){
	                   if(a[i][j]==a[i+1][j]&&a[i+1][j]==a[i+2][j]&&a[i+2][j]==a[i+3][j]&&a[i+1][j]==num){
	                       return true;
	                   }
	            }
	            
	            
	            
	            
	            if(j>=3){
	                   if(a[i][j]==a[i][j-1]&&a[i][j-1]==a[i][j-2]&&a[i][j-2]==a[i][j-3]&&a[i][j-1]==num){
	                       return true;
	                   }
	            }
	            if(j<=2){
	                   if(a[i][j]==a[i][j+1]&&a[i][j+1]==a[i][j+2]&&a[i][j+2]==a[i][j+3]&&a[i][j+1]==num){
	                       return true;
	                   }
	            }
	            
	            
	            
	            
	        }
	    }
		return false;
	}
	
}
