// SPDX-License-Identifier: MIT

import './token/BEP721Enumerable.sol';
import './interfaces/IBEP2981.sol';
import './utils/Ownable.sol';
import './utils/ReentrancyGuard.sol';

contract PunkKnights is BEP721Enumerable, IBEP2981, Ownable, ReentrancyGuard {
    using Strings for uint256;

    string public bornKnightsURI; 
    string public knightExtension = ".json"; 
    uint256 public publicPrice = 500000000000000000; 
    uint256 public whitelistPrice = 200000000000000000; 
                                    
    uint256 public constant maxKnights = 1125; 
    uint256 public maxMintAmount = 5; 
    uint256 public maxKnightsInWallet = 5; 
    bool public paused = true; 
    bool public revealed = true;
    string public unbornKnightsUri; 
    mapping(address => bool) public whitelistWallets;

    address private _royaltiesReceiver; 
    uint256 private _royaltiesPercentage; 

    struct whitelist {
        address addr;
        uint hasMinted;
    }   

    constructor(
        string memory _initBornKnightsURI,
        string memory _initUnbornKnightsUri,
        address royalties        
    ) BEP721("Punk Knights", "Knight") {
        setBornKnightsURI(_initBornKnightsURI);
        setUnbornKnightsURI(_initUnbornKnightsUri);  
        setRoyaltyInfo(royalties, 1000);      
    } 

    function _bornKnightsURI() internal view virtual override returns (string memory) {
        return bornKnightsURI;
    }

    function mintKnight(uint256 _mintAmount) public payable {
        uint256 knights = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(knights + _mintAmount <= maxKnights);
        require(balanceOf(msg.sender) + _mintAmount <= maxKnightsInWallet, "Each address may only own five knights");       


        if (msg.sender != owner()) {
                if (whitelistWallets[msg.sender] != true) {
                    require(msg.value >= publicPrice * _mintAmount);
                } else {
                    require(msg.value >= whitelistPrice * _mintAmount);
                }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            if (totalSupply() <= maxKnights) {
            _safeMint(msg.sender, knights + i);
            }
        }
    }

    function reserveKnights() public onlyOwner {        
        uint knights = totalSupply();
        uint i;
        for (i = 1; i < 51; i++) {
            _safeMint(msg.sender, knights + i);
        }
    }   

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "BEP721Metadata: URI query for nonexistent token");
        if(revealed == false) {return unbornKnightsUri;
    }        

    string memory currentBornKnightsURI = _bornKnightsURI();
        return
            bytes(currentBornKnightsURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBornKnightsURI,
                        tokenId.toString(),
                        knightExtension
                    )
                )
                : "";
    }

    function revealUnbornKnights() public onlyOwner {
        revealed = true;
    }

    function setPublicPrice(uint256 _publicPrice) public onlyOwner {
        publicPrice = _publicPrice;
    }

    function setWhitelistPrice(uint256 _whitelistPrice) public onlyOwner {
        whitelistPrice = _whitelistPrice;
    }

    function setMaxMintAmount(uint256 _newMaxMintAmount) public onlyOwner {
        maxMintAmount = _newMaxMintAmount;
    }

    function setUnbornKnightsURI(string memory _unbornKnightsURI) public onlyOwner {
        unbornKnightsUri = _unbornKnightsURI; 
    }

    function setBornKnightsURI(string memory _newBornKnightsURI) public onlyOwner {
        bornKnightsURI = _newBornKnightsURI;
    }

    function setMaxKnightsInWallet(uint256 _maxKnightsInWallet) public onlyOwner {
        maxKnightsInWallet = _maxKnightsInWallet;
    }

    function setKnightExtension(string memory _newKnightExtension) public onlyOwner {
        knightExtension = _newKnightExtension;
    }    

    function pauseNfkMint(bool _state) public onlyOwner {
        paused = _state;
    }

    function addKnightToWhitelist(address _user) public onlyOwner {
        whitelistWallets[_user] = true;
    }

    function addKnightsToWhitelist(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistWallets[_users[i]] = true;
        }
    }    

    function removeWhitelistedKnight(address _user) public onlyOwner {
        whitelistWallets[_user] = false;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
    }

    function withdrawTreasure() external onlyOwner () {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function setRoyaltyInfo(address royaltiesReceiver, uint256 royaltiesPercentage) public onlyOwner (){
        _royaltiesReceiver = royaltiesReceiver;
        _royaltiesPercentage = royaltiesPercentage;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256 royaltyAmount) {
        tokenId;
        royaltyAmount = (salePrice / 10000) * _royaltiesPercentage;
        return (_royaltiesReceiver, royaltyAmount);
    }
}