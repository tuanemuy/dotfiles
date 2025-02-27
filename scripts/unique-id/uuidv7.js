const fs = require("fs");
const { v7: uuidv7 } = require("uuid");

fs.writeSync(1, uuidv7());
