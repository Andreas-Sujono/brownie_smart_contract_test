from brownie import accounts, config, SimpleStorage, network

def deploy_simple_storage():
    account = get_account()
    print('deploying...')
    simple_storage = SimpleStorage.deploy({"from": account})
    stored_value = simple_storage.retrieve()
    print('stored value: ', stored_value)
    transaction = simple_storage.store(15, {"from": account})
    transaction.wait(1)
    updated_stored_value = simple_storage.retrieve()
    print('updated_stored_value: ', updated_stored_value)


def get_account():
    if network.show_active() == "development":
        return accounts[0]
    if network.show_active() == "ganache-local":
        return accounts.add(config["networks"][network.show_active()]["from_key"])
    else:
        return accounts.add(config["wallets"]["from_key"])


def main():
    deploy_simple_storage()