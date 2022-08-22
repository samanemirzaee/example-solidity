// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract myContact
{
    struct Bid{
        address payable buyer;
        uint amount;        //Deposit
        uint time;          //Validity time
        bool isFinished;    //Just for this bid
    }
    
    struct Post{
        address payable seller; //Beneficiary
        uint minBid;
        string name;
        uint time;          //DeadLine time
        uint biddingEndTime;

        address highestBidder;
        uint highestBid;
        bool Ended;
    }

    Post[] posts;
    mapping (uint=>Bid[]) bids;
    mapping (address => uint) balances;

    //Creat a new post like an NFT  
    function createPost(string memory _name, uint _minBid, uint _biddingTime) public
    {
        posts.push(Post
        ({
        seller:payable(msg.sender), 
        minBid:_minBid, 
        name:_name, 
        time: block.timestamp,
        biddingEndTime:block.timestamp + _biddingTime,  //Hpw long we want this post to be avalable for bidding
        highestBidder: address(0),
        highestBid: 0,
        Ended: false
        }));
    }

    //Create Bid on a post with that's ID Number
    function createBid(uint _postId) public payable{
        Post memory post=posts[_postId];        
        uint count;
        require(msg.sender!=post.seller,"you cant bid on your own post");
        require(msg.value!=0,"Invalid amount of Bid");
        require(post.biddingEndTime>block.timestamp,"this auction is ended");
        require(msg.value>=post.minBid*1000000000000000000,"this bid needs to be more than minBid");

        if(bids[_postId].length > 0){
            require(msg.value > bids[_postId][bids[_postId].length - 1].amount,"this bid needs to be more than last bid");
            for(uint i=0;i<bids[_postId].length;i++){
                if(bids[_postId][i].buyer==msg.sender){
                    count++;
                } 
            }
        }
       
        if(count<=1){
            bids[_postId].push(Bid({
                amount:msg.value,
                buyer:payable(msg.sender),
                time:block.timestamp,
                isFinished:false
            }));
            balances[msg.sender]+=msg.value;
        }else{
            revert("You can only bid twice");
        }
    }

    //Get balance based on address
    function getBalance(address _address) public view returns (uint){
        return balances[_address]/1000000000000000000;
    }

    //Total Bids based on postID
    function totalBids(uint _postId) public view returns (uint){
        Post memory post=posts[_postId];
        require(msg.sender==post.seller, "you dont have permission");
        return bids[_postId].length;
    }

    //Pass detail of bid/buyer for a Certain post
    function getPostBid(uint _postId, uint _bidId)
    public view returns (address buyer, uint amount, uint time)
    {
        Post memory post=posts[_postId];
        Bid memory bid=bids[_postId][_bidId];
        require(msg.sender==post.seller, "you dont have permission");
        return(bid.buyer, bid.amount/1000000000000000000, bid.time);
    }

    //Button to finish the Auction
    function AuctionEnd(uint _postId) public payable{
        if(bids[_postId].length > 0)
        {
            Post memory post=posts[_postId];
            Bid storage bid=bids[_postId][bids[_postId].length-1];
            Bid[] storage listBid=bids[_postId];

            require(msg.sender==post.seller, "you dont have permission");
            require(bid.isFinished==false, "the auction has ended");
            require(post.biddingEndTime <block.timestamp,"the bid has expired");
            bid.isFinished=true;
            uint payment=bid.amount;
            bid.amount=0;
            balances[bid.buyer]-=payment;
            post.seller.transfer(payment);
            for(uint i;i<listBid.length-1;i++){
                if(listBid[i].isFinished==false){
                    payment=listBid[i].amount;
                    listBid[i].isFinished=true;
                    listBid[i].amount=0;
                    balances[listBid[i].buyer]-=payment;
                    listBid[i].buyer.transfer(payment);
                }
            }
        }else{
            revert("There is no suggestion");
        }

    }

}