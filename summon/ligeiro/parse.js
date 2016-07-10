/* Parse ligeiro advertisements */

var parse_advertisement = function (advertisement, cb) {

    if (advertisement.localName === 'ligeiro') {
        if (advertisement.manufacturerData) {
            // Need at least 3 bytes. Two for manufacturer identifier and
            // one for the service ID.
            if (advertisement.manufacturerData.length >= 3) {
                // Check that manufacturer ID and service byte are correct
                var manufacturer_id = advertisement.manufacturerData.readUIntLE(0, 2);
                var service_id = advertisement.manufacturerData.readUInt8(2);
                if (manufacturer_id == 0x02E0 && service_id == 0x18) {
                    // OK! This looks like a ligeiro packet
                    if (advertisement.manufacturerData.length >= 4) {
                        var version = advertisement.manufacturerData.readUInt8(3);
                        var data = advertisement.manufacturerData.slice(4);

                        // We know how to parse version 1
                        if (version == 1 && data.length == 9) {
                            var monjolo_version = data.readUInt8(0);
                            var counter = data.readUIntLE(1,4);
                            var seq_no = data.readUIntLE(5,4);

                            var devices = {
                                1: 'Coilcube',
                                2: 'sEHnsor',
                                3: 'Impulse',
                                4: 'Coilcube (Splitcore)',
                                5: 'Gecko Power Supply',
                                6: 'Buzz',
                                7: 'Thermes',
                                8: 'Ligeiro'
                            };

                            var out = {
                                device: devices[monjolo_version],
                                counter: counter,
                                seq_no: seq_no
                            };

                            cb(out);
                            return;
                        }
                    }
                }
            }
        }
    }

    cb(null);
}


module.exports = {
    parseAdvertisement: parse_advertisement
};
