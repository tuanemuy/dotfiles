const fs = require("fs");
const { createId } = require("@paralleldrive/cuid2");

fs.writeSync(1, createId());
