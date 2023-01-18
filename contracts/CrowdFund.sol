// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC20 {
    function transfer(address, uint) external returns (bool);

    function transferFrom(
        address,
        address,
        uint
    ) external returns (bool);
}


    /** 
    * @title CrowdFund Smart Contract
    * @author Vedant Chainani
    */

contract CrowdFund {
    struct Campaign {       //- A struct for storing data on the campaign's creator, aim, start time, end time, and the pledged tokens.
        address creator;
        uint goal;
        uint pledged;
        uint startAt;
        uint endAt;
        bool claimed;
    }

    IERC20 public immutable token; //to refer to the ERC-20 Token contract used for token transfers.
    uint public count;             //to keep track of campaigns.
    uint public maxDuration;       //Specify the maximum duration a campaign can be hosted.
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount; //a mapping to link the user's address and the number of tokens they pledged, and another mapping to link the campaign id

//some events that will occur if a campaign is started, a token is pledged or unpledged, a campaign is cancelled, or a token is claimed or withdrawn.

    event Launch(
        uint id,
        address indexed creator,
        uint goal,
        uint32 startAt,
        uint32 endAt
    );
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed caller, uint amount);

    constructor(address _token, uint _maxDuration) {    //ERC-20 token address and the maximum time a campaign can be hosted
        token = IERC20(_token);
        maxDuration = _maxDuration;
    }

/*
function, "launch," which accepts the campaign's goal, the start timestamp, and the end timestamp, is now defined.
Before starting the campaign, we first perform some checks.

We determine whether the commencement time exceeds the current time.
We make sure the end time is later than the beginning time.
Finally, we make sure the campaign does not go beyond its maximum time.
After that, we raise our count variable.
The campaign information is then stored in the campaigns mapping, 
with the count variable serving as the key and a struct as the value.
*/

    function launch(uint _goal, uint32 _startAt, uint32 _endAt) external { 
        require(_startAt >= block.timestamp,"Start time is less than current Block Timestamp");
        require(_endAt > _startAt,"End time is less than Start time");
        require(_endAt <= block.timestamp + maxDuration, "End time exceeds the maximum Duration");

        count += 1;
        campaigns[count] = Campaign({
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });

        emit Launch(count,msg.sender,_goal,_startAt,_endAt);
    }

/*
function called cancel, 
which allows the campaign's creator to end the campaign provided that they are the campaign's creator
 and that the campaign has not yet begun.
*/

    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "You did not create this Campaign");
        require(block.timestamp < campaign.startAt, "Campaign has already started");

        delete campaigns[_id];
        emit Cancel(_id);
    }

/*
 pledge functon feature, which asks for the campaign id and the number of tokens that need to be pledged
*/ 

    function pledge(uint _id, uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "Campaign has not Started yet");
        require(block.timestamp <= campaign.endAt, "Campaign has already ended");
        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }

/*
function called unpledge that removes the tokens that a user has pledged, just as the pledge function.
*/

    function unPledge(uint _id,uint _amount) external {
        Campaign storage campaign = campaigns[_id];
        require(block.timestamp >= campaign.startAt, "Campaign has not Started yet");
        require(block.timestamp <= campaign.endAt, "Campaign has already ended");
        require(pledgedAmount[_id][msg.sender] >= _amount,"You do not have enough tokens Pledged to withraw");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);
    }

/*
The creator can claim all of the tokens raised for the campaign with the help of a claim function that we define next if the following criteria are met.

the campaign's originator is the one who called the function.
The campaign has come to a close.
The objective has been surpassed by the quantity of tokens raised (campaign succeded)
The tokens have not yet been redeemed.
*/

    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        require(campaign.creator == msg.sender, "You did not create this Campaign");
        require(block.timestamp > campaign.endAt, "Campaign has not ended");
        require(campaign.pledged >= campaign.goal, "Campaign did not succed");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(campaign.creator, campaign.pledged);

        emit Claim(_id);
    }

/*
If the campaign is unsuccessful, 
we create a refund function that allows users to withdraw their tokens from the contract.
*/
    function refund(uint _id) external {
        Campaign memory campaign = campaigns[_id];
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, "You cannot Withdraw, Campaign has succeeded");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }


}