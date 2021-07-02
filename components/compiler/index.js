const fs = require("fs");
const { exec } = require("child_process");

const execPromise = (cmd) => {
  return new Promise(function (resolve, reject) {
    exec(cmd, function (err, stdout) {
      if (err) return reject(err);
      resolve(stdout);
    });
  });
};

const compile = (smcNames) => {
  const compileScripts = [];
  if (!fs.existsSync("build")) compileScripts.push(`mkdir build`);
  if (!fs.existsSync("ton-packages")) compileScripts.push(`mkdir ton-packages`);

  smcNames.forEach((name) => {
    compileScripts.push(`npx tondev sol compile -o ./build ./src/${name}.sol`);
  });

  compileScripts
    .reduce(
      (p, cmd) =>
        p.then((results) =>
          execPromise(cmd).then((stdout) => {
            results.push(stdout);
            return results;
          })
        ),
      Promise.resolve([])
    )
    .then(
      (/* results */) => {
        smcNames.forEach((name) => {
          const abiRaw = fs.readFileSync(`./build/${name}.abi.json`);
          const abi = JSON.parse(abiRaw);
          const image = fs.readFileSync(`./build/${name}.tvc`, {
            encoding: "base64",
          });

          fs.writeFileSync(
            `./ton-packages/${name}.package.ts`,
            `export default ${JSON.stringify({ abi, image })}`
          );
        });
      },
      console.log
    );
};

module.exports = {
  compile,
};
