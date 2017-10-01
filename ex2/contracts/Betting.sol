pragma solidity ^0.4.15;

contract Betting {
	/* Standard state variables */
	address public owner;
	address public gamblerA;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;	// Feel free to replace with a mapping

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed(); //when 2 gamblers gamble
	event DecisionMade(); //when oracle decides or when game ends (when winnings dispersed)

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
	    if (msg.sender!=owner) {
	        return;
	    }
	    _;}
	modifier OracleOnly() {
	    if (msg.sender!=oracle) {
	        return;
	    }
	    _;}

	/* Constructor function, where owner and outcomes are set */
	function Betting() {
	    owner = msg.sender;
	}

	function BettingContract(uint[] _outcomes) OwnerOnly() {
	    if (_outcomes.length < 1) {
	        revert();
	        return;
	    }
	    outcomes = _outcomes;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
	    if (_oracle != gamblerA && _oracle != gamblerB) {
	        oracle = _oracle;
	        return oracle;
	    }
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
	    //checks to see if sender is already a gambler or oracle
	    if (msg.sender == gamblerA || msg.sender == gamblerB || msg.sender == oracle || msg.sender == owner) {
	        revert();
	        return false;
	    }
	    //checks if value is greater than 0 (no bet of zero)
	    if (msg.value < 1) {
	        revert();
	        return false;
	    }
	    //will check if gamblers initialized
	    if (gamblerA == 0) {
	        gamblerA = msg.sender;
	        bets[gamblerA] = Bet(_outcome, msg.value, true);
	        BetMade(msg.sender);
	        return true;
	    } else if (gamblerB == 0) {
	        gamblerB = msg.sender;
	        bets[gamblerB] = Bet(_outcome, msg.value, true);
	        BetMade(msg.sender);
	        BetClosed();
	        //checks if both gamblers bet same outcome it will refund them and reset
	        if (bets[gamblerB].outcome == bets[gamblerA].outcome) {
	            winnings[gamblerA] += bets[gamblerA].amount;
	            winnings[gamblerB] += bets[gamblerB].amount;
	            DecisionMade();
	            contractReset();
	        }
	        return true;
	    } else {
	        //if both gambler a nor b are initialized
	        revert();
	        return false;
	    }
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
	    //check if _outcome is in array
	    bool isIn = false;
	    for (uint i = 0; i < outcomes.length; i++) {
	        if (outcomes[i] == _outcome) {
	            isIn = true;
	            break;
	        }
	    }
	    //check if both bets are in
	    if (!isIn || gamblerA == 0 || gamblerB == 0) {
	        revert();
	        return;
	    }

	    if (bets[gamblerA].outcome == _outcome) {
	        winnings[gamblerA] += bets[gamblerA].amount + bets[gamblerB].amount;
	        contractReset();
	    } else if (bets[gamblerB].outcome == _outcome) {
	        winnings[gamblerB] += bets[gamblerA].amount + bets[gamblerB].amount;
	        contractReset();
	    } else {
	        winnings[oracle] += bets[gamblerA].amount + bets[gamblerB].amount;
	        contractReset();
	    }
	    DecisionMade();
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
	    if (winnings[msg.sender] >= withdrawAmount) {
	        winnings[msg.sender] -= withdrawAmount;
	        msg.sender.transfer(withdrawAmount);
	    }
	    remainingBal =  winnings[msg.sender];
	}

	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
	    return outcomes;
	}

	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
	    return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
	    delete(bets[gamblerA]);
	    delete(bets[gamblerB]);
	    delete(gamblerA);
	    delete(gamblerB);
	    delete(oracle);
	}

	/* Fallback function */
	function() payable {
		revert();
	}
}
