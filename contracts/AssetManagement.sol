pragma solidity ^0.4.25;

contract AssetManagement {

    /*** Event ***/
    event TypeAdded (
        address _sender,
        string  _name
    );

    event AssetAdded (
        address _sender,
        string  _type,
        string  _name
    );

    event StatusChanged (
        address _sender,
        string  _id,
        string  _status
    );

    /*** Struct ***/
    struct Asset {
        string name;
        string timestamp;
        string id;
        string status;
    }

    /*** Property ***/
    string[] types;
    Asset[] assets;

    // タイプの一覧
    mapping(address => uint256[]) typeIndex;

    // 資産の一覧
    mapping(address => uint256[]) assetIndex;

    // タイプと資産の紐付け：typeIndex => assetIndex
    mapping(uint256 => uint256[]) type2asset;

    // 資産のレンタル履歴：assetIndex => Asset
    mapping(uint256 => Asset[]) assetHistory;

    function AddType(string memory name) public {
        // bytes のデータを取得
        bytes memory b = bytes(name);

        // name が空の場合はエラー
        if (b.length == 0) {
            revert("wrong argument");
        }

        // 重複確認
        uint256 count = typeIndex[msg.sender].length;
        uint256 i;
        for (i = 0; i < count; i++) {
            if (keccak256(types[typeIndex[msg.sender][i]]) == keccak256(name)) {
                revert("already registered");
            }
        }

        // 配列に登録
        types.push(name);

        // アドレスごとにインデックスを保存
        i = types.length - 1;
        typeIndex[msg.sender].push(i);

        emit TypeAdded(msg.sender, name);
    }

    function AddAsset(string memory typeName, string memory asset, string timestamp, string memory id) public {
        uint256 typeId = 0;

        // bytes のデータを取得
        bytes memory bType      = bytes(typeName);
        bytes memory bAsset     = bytes(asset);
        bytes memory bTimestamp = bytes(timestamp);
        bytes memory bId        = bytes(id);

        // 必須パラメータが空の場合はエラー
        if (bType.length == 0 || bAsset.length == 0 || bTimestamp.length == 0 || bId.length == 0) {
            revert("wrong argument");
        }

        // タイプの存在確認
        uint256 count = typeIndex[msg.sender].length;
        uint256 i;
        bool isExist = false;
        for (i = 0; i < count; i++) {
            if (keccak256(types[typeIndex[msg.sender][i]]) == keccak256(typeName)) {
                typeId = typeIndex[msg.sender][i];
                isExist = true;
                break;
            }
        }
        if (!isExist) {
            revert("Type nod found. Use AddType to create it.");
        }

        // アセットのIDの重複確認
        count = assetIndex[msg.sender].length;
        for (i = 0; i < count; i++) {
            if (keccak256(assets[assetIndex[msg.sender][i]].id) == keccak256(id)) {
                revert("This asset is already registered.");
            }
        }

        // 配列に登録
        Asset memory a;
        a.name      = asset;
        a.timestamp = timestamp;
        a.id        = id;
        a.status    = "in-stock";
        assets.push(a);

        // 履歴に登録
        assetHistory[assets.length - 1].push(a);

        // アドレスごとにインデックスを保存
        i = assets.length - 1;
        assetIndex[msg.sender].push(i);

        // タイプと資産の紐付け
        type2asset[typeId].push(i);

        emit AssetAdded(msg.sender, typeName, asset);
    }

    function ListType() public view returns (string) {
        uint256 count = typeIndex[msg.sender].length;
        uint256 total = 0;
        string memory sep = "/";
        bytes memory s = bytes(sep);
        uint256 i;
        bytes memory b;

        // 全体の長さを取得
        total = total + s.length;
        for (i = 0; i < count; i++) {
            b = bytes(types[typeIndex[msg.sender][i]]);
            total = total + b.length + s.length;
        }

        // 文字列の連結
        bytes memory ret = new bytes(total);
        uint256 index = 0;
        uint256 j;
        for (j = 0; j < s.length; j++) {
            ret[index] = s[j];
            index++;
        }
        for (i = 0; i < count; i++) {
            b = bytes(types[typeIndex[msg.sender][i]]);
            for (j = 0; j < b.length; j++) {
                ret[index] = b[j];
                index++;
            }
            for (j = 0; j < s.length; j++) {
                ret[index] = s[j];
                index++;
            }
        }

        return string(ret);
    }

    function List(string memory typeName) public view returns (string) {
        uint256 typeId = 0;

        // bytes のデータを取得
        bytes memory b = bytes(typeName);

        // type が空の場合はエラー
        if (b.length == 0) {
            revert("wrong argument");
        }

        // タイプの存在確認
        uint256 count = typeIndex[msg.sender].length;
        uint256 i;
        bool isExist = false;
        for (i = 0; i < count; i++) {
            if (keccak256(types[typeIndex[msg.sender][i]]) == keccak256(typeName)) {
                typeId = typeIndex[msg.sender][i];
                isExist = true;
                break;
            }
        }
        if (!isExist) {
            revert("Type nod found. Use AddType to create it.");
        }

        // 対象のタイプに含まれる資産をリストアップ
        count = type2asset[typeId].length;
        uint256 total = 0;
        string memory sep = "/";
        bytes memory s = bytes(sep);
        string memory colon = ":";
        bytes memory c = bytes(colon);

        // 全体の長さを取得
        total = total + s.length;
        for (i = 0; i < count; i++) {
            // id
            b = bytes(assets[type2asset[typeId][i]].id);
            total = total + b.length + c.length;
            // name
            b = bytes(assets[type2asset[typeId][i]].name);
            total = total + b.length + c.length;
            // timestamp
            b = bytes(assets[type2asset[typeId][i]].timestamp);
            total = total + b.length + c.length;
            // status
            b = bytes(assets[type2asset[typeId][i]].status);
            total = total + b.length + s.length;
        }

        // 文字列の連結
        bytes memory ret = _createListBytes(typeId, count, total);
        return string(ret);
    }

    function _createListBytes(uint256 typeId, uint256 count, uint256 total) returns (bytes ret) {
        ret = new bytes(total);

        string memory sep = "/";
        bytes memory s = bytes(sep);
        string memory colon = ":";
        bytes memory c = bytes(colon);
        bytes memory b;
        uint256 index = 0;
        uint256 i;
        uint256 j;
        for (j = 0; j < s.length; j++) {
            ret[index] = s[j];
            index++;
        }
        for (i = 0; i < count; i++) {
            // id
            b = bytes(assets[type2asset[typeId][i]].id);
            for (j = 0; j < b.length; j++) {
                ret[index] = b[j];
                index++;
            }
            for (j = 0; j < c.length; j++) {
                ret[index] = c[j];
                index++;
            }
            // name
            b = bytes(assets[type2asset[typeId][i]].name);
            for (j = 0; j < b.length; j++) {
                ret[index] = b[j];
                index++;
            }
            for (j = 0; j < c.length; j++) {
                ret[index] = c[j];
                index++;
            }
            // timestamp
            b = bytes(assets[type2asset[typeId][i]].timestamp);
            for (j = 0; j < b.length; j++) {
                ret[index] = b[j];
                index++;
            }
            for (j = 0; j < c.length; j++) {
                ret[index] = c[j];
                index++;
            }
            // status
            b = bytes(assets[type2asset[typeId][i]].status);
            for (j = 0; j < b.length; j++) {
                ret[index] = b[j];
                index++;
            }
            for (j = 0; j < s.length; j++) {
                ret[index] = s[j];
                index++;
            }
        }
        return ret;
    }

    function toBytes(uint256 x) returns (bytes b) {
        b = new bytes(32);
        //assembly { mstore(add(b, 32), x) }
        for (uint i = 0; i < 32; i++) {
            b[i] = byte(uint8(x / 2**(8*(31 - i))));
        }
        return b;
    }

    function StateChange(string id, string status, string timestamp) public {
        // bytes のデータを取得
        bytes memory bAssetId   = bytes(id);
        bytes memory bStatus    = bytes(status);
        bytes memory bTimestamp = bytes(timestamp);

        if (bAssetId.length == 0 || bStatus.length == 0 || bTimestamp.length == 0) {
            // 必須パラメータが空の場合はエラー
            revert("wrong argument");
        } else if (keccak256(status) != keccak256("on-loan") && keccak256(status) != keccak256("in-stock")) {
            // ステータスが想定外の場合はエラー
            revert("wrong argument");
        }

        // 資産の存在確認
        uint256 assetId = 0;
        uint256 count = assetIndex[msg.sender].length;
        uint256 i;
        bool isExist = false;
        for (i = 0; i < count; i++) {
            if (keccak256(assets[assetIndex[msg.sender][i]].id) == keccak256(id)) {
                isExist = true;
                assetId = assetIndex[msg.sender][i];
            }
        }
        if (!isExist) {
            revert("Asset not found.");
        }

        // ステータス確認（on-loan, in-stock）
        if (keccak256(assets[assetId].status) == keccak256(status)) {
            revert("Asset is already ***ed.");
        }

        // ステータス変更
        assets[assetId].status    = status;
        assets[assetId].timestamp = timestamp;

        // 履歴を残す
        Asset memory a;
        a.timestamp = timestamp;
        a.id        = id;
        a.status    = status;
        assetHistory[assetId].push(a);

        // イベント
        if (keccak256(status) == keccak256("on-loan")) {
            emit StatusChanged(msg.sender, id, "Borrowed");
        } else {
            emit StatusChanged(msg.sender, id, "Returned");
        }
    }

    function AssetHistory(string id) public view returns (string) {
        // 必須パラメータが空の場合はエラー
        if (bytes(id).length == 0) {
            revert("wrong argument");
        }

        // 資産の存在確認
        uint256 assetId = 0;
        uint256 count = assetIndex[msg.sender].length;
        uint256 i;
        bool isExist = false;
        for (i = 0; i < count; i++) {
            if (keccak256(assets[assetIndex[msg.sender][i]].id) == keccak256(id)) {
                isExist = true;
                assetId = assetIndex[msg.sender][i];
            }
        }
        if (!isExist) {
            revert("Asset not found.");
        }

        // 文字列の連結
        bytes memory ret = _createHistoryListBytes(assetId);
        return string(ret);
    }

    function _createHistoryListBytes(uint256 assetId) returns (bytes ret) {
        // 対象の資産の履歴をリストアップ
        uint256 count = assetHistory[assetId].length;
        uint256 total = 0;
        string memory sep = "/";
        bytes memory s = bytes(sep);
        string memory colon = ":";
        bytes memory c = bytes(colon);
        bytes memory b;
        uint256 i;

        // 全体の長さを取得
        total = total + s.length;
        for (i = 0; i < count; i++) {
            // timestamp
            b = bytes(assetHistory[assetId][i].timestamp);
            total = total + b.length + c.length;
            // status
            b = bytes(assetHistory[assetId][i].status);
            total = total + b.length + s.length;
        }

        ret = new bytes(total);

        uint256 index = 0;
        uint256 j;
        for (j = 0; j < s.length; j++) {
            ret[index] = s[j];
            index++;
        }
        for (i = 0; i < count; i++) {
            // timestamp
            b = bytes(assetHistory[assetId][i].timestamp);
            for (j = 0; j < b.length; j++) {
                ret[index] = b[j];
                index++;
            }
            for (j = 0; j < c.length; j++) {
                ret[index] = c[j];
                index++;
            }
            // status
            b = bytes(assetHistory[assetId][i].status);
            for (j = 0; j < b.length; j++) {
                ret[index] = b[j];
                index++;
            }
            for (j = 0; j < s.length; j++) {
                ret[index] = s[j];
                index++;
            }
        }
        return ret;
    }

}
