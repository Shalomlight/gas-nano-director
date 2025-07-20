import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.0.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Gas Director: Verify initial contract state",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const block = chain.mineBlock([
            Tx.contractCall('gas-director', 'verify-contract-optimization', 
                [types.principal('ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM'), types.ascii('1.0.0')], 
                deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, '(ok false)');
    }
});

Clarinet.test({
    name: "Gas Director: Transfer platform ownership",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        const block = chain.mineBlock([
            Tx.contractCall('gas-director', 'transfer-ownership', 
                [types.principal(wallet1.address)], 
                deployer.address)
        ]);

        // Verify successful ownership transfer
        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectOk();
    }
});