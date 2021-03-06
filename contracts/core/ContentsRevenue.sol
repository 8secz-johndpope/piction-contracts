pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

import "../interfaces/IPictionNetwork.sol";
import "../interfaces/IContentsRevenue.sol";
import "../utils/ValidValue.sol";

contract ContentsRevenue is Ownable, IContentsRevenue, ValidValue {
    using SafeMath for uint256;

    IPictionNetwork private pictionNetwork;
    
    uint256 private constant DECIMALS = 10 ** 18;
    string private constant USERADOPTIONPOOL = "UserAdoptionPool";
    string private constant ECOSYSTEMFUND = "EcosystemFund";
    string private constant SUPPORTERPOOL = "SupporterPool";

    struct DistributionInfo {
        uint256 contentsDistributor;
        uint256 userAdoptionPool;
        uint256 ecosystemFund;
        uint256 supporterPool;
    }

    constructor(address pictionNetworkAddress) public validAddress(pictionNetworkAddress) {
        pictionNetwork = IPictionNetwork(pictionNetworkAddress);
    }

    /**
     * @dev 전송된 PXL을 각 비율별로 계산
     * @param cdRate ContentsDistributor의 분배 비율
     * @param cp 구독한 project의 작가 주소
     * @param amount 전송받은 PXL 수량
     */
    function calculateDistributionPxl(
        uint256 cdRate, 
        address cp, 
        uint256 amount
    )
        external 
        view
        validRate(cdRate)
        validAddress(cp)
        returns(address[] memory addresses, uint256[] memory amounts)
    {   
        addresses = new address[](4);
        amounts = new uint256[](4);

        // TODO: 주석 내용 처리, PIC, DepositPool 등의 컨트랙트 수수료 적용
        DistributionInfo memory distributionInfo = DistributionInfo(
            amount.mul(cdRate).div(DECIMALS),
            0,// amount.mul(pictionNetwork.getRate(USERADOPTIONPOOL)).div(DECIMALS),
            0,// amount.mul(pictionNetwork.getRate(ECOSYSTEMFUND)).div(DECIMALS),
            0// amount.mul(pictionNetwork.getRate(SUPPORTERPOOL)).div(DECIMALS) 
        );

        addresses[0] = pictionNetwork.getAddress(USERADOPTIONPOOL);
        amounts[0] = distributionInfo.userAdoptionPool;
        
        addresses[1] = pictionNetwork.getAddress(ECOSYSTEMFUND);
        amounts[1] = distributionInfo.ecosystemFund;

        //TODO: 등록되지 않은 주소를 조회할 경우 revert, PIC가 설계되면 코드 수정 필요
        addresses[2] = owner();         // pictionNetwork.getAddress(SUPPORTERPOOL);
        amounts[2] = distributionInfo.supporterPool;

        addresses[3] = cp;
        amounts[3] = amount.sub(distributionInfo.contentsDistributor).sub(distributionInfo.userAdoptionPool).sub(distributionInfo.ecosystemFund).sub(distributionInfo.supporterPool);
    }
}