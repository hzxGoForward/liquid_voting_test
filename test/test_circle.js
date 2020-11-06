const LiquidDemocracy = artifacts.require("LiquidDemocracy");
const { BN, constants, expectEvent, expectRevert } = require('openzeppelin-test-helpers');
const { expect } = require('chai');
const {VNode, VGraph} = require("./Preparer.js");
const { assert } = require('console');
const SimpleVote = artifacts.require('SimpleVote');
const LiquidVote = artifacts.require('LiquidVote');
const SimpleVoteFactory = artifacts.require('SimpleVoteFactory');
const LiquidVoteFactory = artifacts.require('LiquidVoteFactory');

contract('TestChain', (accounts) => {

    let democracy = {};
    let vcount = 100;
    let vg = {};
    let svote = {};
    let lvote = {};

    context('init', async () => {
        democracy = await LiquidDemocracy.deployed();
        assert(democracy);
        vg = VGraph.createNew();
    })


    context("delegate", () => {

        it('test construct delegate graph', async () => {

            // 这段代码首先建立一张代理图,自下往上建立代理关系
            /*
                                1
                               / \
                              2   3
                            / | \  \
                           4  5  6  7
                                     \
                                      8
                                     /  \
                                    9   10
                                  / | \
                                11 12 13 
                                    | 
                                   14
                                    | 
                                   15
            */
            for (i = 1; i < vcount; ++i) {
                await democracy.setWeight(accounts[i], 1);
                n = VNode.createNew(accounts[i], 1, 0, 0, 0, 0, 0);
                vg.addNode(n);
            }
            // 
            var arr = [[2, 1], [3, 1], [4, 2], [5, 2], [6, 2], [7, 3], [8, 7], [9, 8], [10, 8], [11, 9], [12, 9], [13, 9], [14, 12], [15, 14]];
            for (var i = 0; i < arr.length; ++i) {
                var delegator = arr[i][0];
                var delegatee = arr[i][1];
                console.log("%d -> %d\n", delegator, delegatee);
                succ = false;
                try {
                    await democracy.delegate(accounts[delegatee], { from: accounts[delegator] });
                    succ = true;
                }
                catch (error) {
                    console.log(error);
                    console.log('retry...');
                }
                vg.addEdge(accounts[delegator], accounts[delegatee]);
            }
        }),
    
        it('test circle delegate', async () => {
            for (i = 1; i < vcount; ++i) {
                await democracy.setWeight(accounts[i], 1);
                n = VNode.createNew(accounts[i], 1, 0, 0, 0, 0, 0);
                vg.addNode(n);
            }
            // 下列这段代码进行环形检测
            // 应该全部失败
            var arr2 = [[1, 2], [1, 7], [1, 8], [8, 3], [9,3], [10, 1], [12, 3], [14, 6], [15, 4], [11, 2], [12, 10], [13, 1], [14, 5], [15, 4]];
            for (var i = 0; i < arr2.length; ++i) {
                var delegator = arr2[i][0];
                var delegatee = arr2[i][1];
                console.log("%d -> %d\n", delegator, delegatee);
                succ = false;
                try {
                    await democracy.delegate(accounts[delegatee], { from: accounts[delegator] });
                    succ = true;
                }
                catch (error) {
                    console.log(error);
                    console.log('retry...');
                }
                vg.addEdge(accounts[delegator], accounts[delegatee]);
            }
        }),
            it('test change delegatee', async () => {
        
                /*
                         1
                        / \
                        2   3
                      / | \  \
                     4  5  6  7            16
                                            |
                                            8
                                            / \
                                           10
                                    17
                                    |
                                    9
                                / | \
                                11 12 13 
                                    | 
                                    14
                                    | 
                                    15
        */
        for (i = 1; i < vcount; ++i) {
            await democracy.setWeight(accounts[i], 1);
            n = VNode.createNew(accounts[i], 1, 0, 0, 0, 0, 0);
            vg.addNode(n);
        }
            // 倒数第一个非法，其他全部合法
            var arr3 = [[8, 16], [9, 17], [14,10], [11, 10], [16, 3], [17,1], [17,2]];
            for (var i = 0; i < arr3.length; ++i) {
                var delegator = arr3[i][0];
                var delegatee = arr3[i][1];
                console.log("%d -> %d\n", delegator, delegatee);
                succ = false;
                try {
                    await democracy.delegate(accounts[delegatee], { from: accounts[delegator] });
                    succ = true;
                }
                catch (error) {
                    console.log(error);
                    console.log('retry...');
                }
                vg.addEdge(accounts[delegator], accounts[delegatee]);
            }
        }),
            it('test undelegate', async () => {
        
                /*
                         1
                        / \
                        2   3
                      / | \  \
                     4  5  6  7            16
                                            |
                                            8
                                            / \
                                           10
                                    17
                                    |
                                    9
                                / | \
                                11 12 13 
                                    | 
                                    14
                                    | 
                                    15
        */
        for (i = 1; i < vcount; ++i) {
            await democracy.setWeight(accounts[i], 1);
            n = VNode.createNew(accounts[i], 1, 0, 0, 0, 0, 0);
            vg.addNode(n);
        }
        // 倒数第一个非法，其他全部合法
        var arr3 = [[8, 16], [9, 17], [14,10], [11, 10], [16, 3], [17,1], [17,2]];
        for (var i = 0; i < arr3.length; ++i) {
            var delegator = arr3[i][0];
            var delegatee = arr3[i][1];
            console.log("%d -> %d\n", delegator, delegatee);
            succ = false;
            try {
                await democracy.undelegate(accounts[delegator]);
                succ = true;
            }
            catch (error) {
                console.log(error);
                console.log('retry...');
            }
        }
    })

    })
});
