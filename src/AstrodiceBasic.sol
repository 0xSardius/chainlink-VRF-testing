// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AstrodiceBasic is ERC721, VRFConsumerBaseV2 {

    // Enums of the Sign, Planet, and House combinations VRF will be used with. 12 each.
    enum Sign { Aries, Taurus, Gemini, Cancer, Leo, Virgo, Libra, Scorpio, Sagittarius, Capricorn, Aquarius, Pisces }
    enum Planet { Sun, Moon, Mercury, Venus, Mars, Jupiter, Saturn, Uranus, Neptune, Pluto, NorthNode, SouthNode }
    enum House { First, Second, Third, Fourth, Fifth, Sixth, Seventh, Eighth, Ninth, Tenth, Eleventh, Twelfth }


    // State variables
    uint64 s_subscriptionId;
    address s_owner;
    VRFCoordinatorV2Interface COORDINATOR;
    address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;
    bytes32 s_keyHash = 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 numWords =  3;

    // Structs
    struct Reading {
        Sign sign;
        Planet planet;
        House house;
    }

    // Store each reading associated with a tokenId
    mapping(uint256 => Reading) public tokenIdToReading;
    // Map each request to the address that made it
    mapping(uint256 => address) private requestToSender;

    event ReadingRequested(uint256 indexed requestId, address indexed requestor);
    event ReadingFulfilled(uint256 indexed requestId, uint256 tokenId);

    constructor(uint64 subscriptionId) ERC721("AstroDice", "ASTRODICE") VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        // s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        // may put a spot here to make keyHash customizeable, need to do more research
    }

    function requestReading(address roller) public returns(uint256 requestId) {
        // require(s_results[roller] == 0, "Already rolled");
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );

        requestToSender[requestId] = msg.sender;
        emit ReadingRequested(requestId, msg.sender);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        uint256 tokenId = totalSupply() + 1;

        // Create the reading
        Reading memory newReading = Reading(
            Sign(randomWords[0] % 12),
            Planet(randomWords[1] % 12),
            House(randomWords[2] % 12)
        );

        tokenIdToReading[tokenId] = newReading;
        _safeMint(requestToSender[requestId], tokenId);

        emit ReadingFulfilled(requestId, tokenId);
    }

   function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    // You could construct a base URI and append the tokenId to it
    string memory baseURI = "https://metadata-server.com/token/";
    return string(abi.encodePacked(baseURI, toString(tokenId)));
}
    // Helper Functions
    function toString(uint256 value) internal pure returns (string memory) {
    return Strings.toString(value);
}   

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}