const { expect } = require("chai");
const { ethers } = require("hardhat");
const { advanceTime, currentTimestamp} = require('./utils');
const provider = waffle.provider;
const Web3 = require("web3");
const { fromWei } = Web3.utils;

describe ('Started Staking', async function () {
        let token, staking;
        beforeEach('Started Staking', async function() {
            [alice,bob] = await ethers.getSigners()
            const Token = await ethers.getContractFactory('SampleToken')
            const Stake = await ethers.getContractFactory('FlexStaking')
            token = await Token.deploy()
            staking = await Stake.deploy(token.address)
        })
    it ('Test1: Try Staking Token', async function(){
        await token.connect(alice)._mintToken(ethers.utils.parseEther('1000'))
        await token.connect(bob)._mintToken(ethers.utils.parseEther('1000'))
        await token.connect(alice).transfer(staking.address,ethers.utils.parseEther('900'))
        await token.connect(alice).approve(staking.address,ethers.utils.parseEther('100'))
        await token.connect(bob).approve(staking.address,ethers.utils.parseEther('900'))
        await staking.connect(bob).stake(ethers.utils.parseEther('100'))
        await staking.connect(alice).stake(ethers.utils.parseEther('100'))
        await advanceTime( 31 * 3600 * 24)
        await staking.connect(alice).withdraw(ethers.utils.parseEther('100'))
        const ROI1 = await token.balanceOf(alice.address)
        console.log(fromWei(ROI1.toString(),"ether"))
    })
})