console.log("\n".repeat(50))
console.log("\x1b[38;2;179;0;0m                                      @@@@@       @@@                                               ")
console.log("                                    @@@@@@@@@@@  @@@@                                               ")
console.log("                                  @@@@  @@@@@@  @@@@@                                               ")
console.log("                                  @@@@          @@@@@                                               ")
console.log("                                  @@@@          @@@@@                                    @          ")
console.log("                      @@        @@@@@@@@@   @@@@@@@@@@         @@         @    @      @@@           ")
console.log("                   @@@@@@@@@    @@@@@@@@@@   @@@@@@@@@@@     @@@@@@@@    @@@@@@@@@@@@@@@            ")
console.log("                @@@@ @@@@@@@@    @@@@@@@@@     @@@@@@@@@@ @@@ @@@@@@@@ @@@@@@@@@@@@@@@              ")
console.log("          @@    @@@@    @@@@@     @@@@          @@@@@    @@@@    @@@@@  @@@@@                       ")
console.log("           @@@@@@@@@     @@@@     @@@@          @@@@@    @@@@    @@@@@  @@@@@                       ")
console.log("              @@@@@     @@@@@     @@@@          @@@@@    @@@@    @@@@@  @@@@@                       ")
console.log("                      @@@@@@@     @@@@          @@@@@    @@@@  @@@@@@@  @@@@@                       ")
console.log("                 @@@@@   @@@@     @@@@          @@@@@    @@@@@@@        @@@@@                       ")
console.log("           @@@@@@@@@     @@@@     @@@@          @@@@@    @@@@@          @@@@@                       ")
console.log("                @@@@     @@@@     @@@@          @@@@@    @@@@           @@@@@                       ")
console.log("                @@@@     @@@@     @@@@          @@@@@    @@@@           @@@@@                       ")
console.log("                @@@@     @@@@     @@@@          @@@@@    @@@@           @@@@@                       ")
console.log("                @@@@@@@@@@@@@@@@ @@@@@@@@@      @@@@@@@ @@@@@@@@@ @@@@  @@@@@@@@                    ")
console.log("                 @@@@@@@@@@@@@@@  @@@@@@@@    @@@@@@@@    @@@@@@@@@@@@   @@@@@@@@                   ")
console.log("                     @@    @@@@@    @@@@@@   @@@@@@@          @@  @@@@     @@@@@@@                  ")
console.log("                            @@@@     @@@@  @@@@@@@                 @@@       @@@@@@                 ")
console.log("                             @@@@    @@  @@@@@                     @@@        @@@@@@                ")
console.log("                               @                                    @@         @@@@@                ")
console.log("                                                                    @@          @@@@                ")
console.log("                                                                                 @@@                \x1b[0m")

const RPC = require("discord-rpc");
const https = require("https");
const fs = require("fs");
const readline = require("readline");
const clientId = "1489770369861816481";
const CONFIG_PATH = "./config.cfg";

const rpc = new RPC.Client({ transport: "ipc" });
RPC.register(clientId);

const EFAS_ARTISTS = ["plaxz", "efas", "may!", "luvkrime", "kelestiial", "ch7nky", "frbrenn", "spraggins hill", "glory", "beidant", "itstalex", "duskydemise", "duskydemise archive", "jay2kz", "manja", "corvid", "felicio"];
const ALBUM_KEYS = {
  "efas": "efas",
  "aletheia": "aletheia",
  "a new something": "anewsomething",
  "star crossed": "starcrossed",
  "pretty view": "prettyview",
  "think": "starcrossed",
  "wildcard": "wildcard",
  "never kept me // on & on": "may",
  "loser luck": "lluck",
  "writing": "writing",
  "bayonet": "bayonet",
  "odyne": "odyne",
  "fvck off": "fvckoff",
  "harakiri": "harakiri",
  "edith": "edith",
  "paparazzi": "paparazzi",
  "your way": "yourway",
  "your way (sped up)": "yourway",
  "devil's peer": "devilspeer",
  "top it!": "topit",
  "wya?": "fuckingstupidcover",
  "attached 2 you": "a2u",
  "endless": "endless",
  "ixtab": "ixtab",
  "state of death": "stateofdeath",
  "up": "up",
  "rich intellect": "richintellect",
  "scraps": "scraps",
  "pyromaniak": "pyromaniak",
  "not enough": "notenough",
  "dysphoria": "dysphoria",
  "blossoms": "blossoms",
  "now we aren't strangers, are we?": "longassname",
  "opal": "opal",
  "impatient ep": "impatient",
  "good things fade": "gtf",
  "doze": "doze",
  "perfect": "perfect",
  "i hear you": "ihearu",
  "skeeter": "skeeter"
};

let lastTrack = null;

function loadConfig() {
  try {
    if (fs.existsSync(CONFIG_PATH)) {
      const raw = fs.readFileSync(CONFIG_PATH, "utf-8");
      const apiKeyMatch = raw.match(/^LASTFM_API_KEY=(.+)$/m);
      const usernameMatch = raw.match(/^LASTFM_USERNAME=(.+)$/m);
      if (apiKeyMatch && usernameMatch) {
        return { apiKey: apiKeyMatch[1].trim(), username: usernameMatch[1].trim() };
      }
    }
  } catch {}
  return null;
}

function saveConfig(apiKey, username) {
  fs.writeFileSync(CONFIG_PATH, `LASTFM_API_KEY=${apiKey}\nLASTFM_USERNAME=${username}\n`);
}

function prompt(question) {
  return new Promise((resolve) => {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

function validateApiKey(apiKey, username) {
  return new Promise((resolve) => {
    const url = `https://ws.audioscrobbler.com/2.0/?method=user.getinfo&user=${username}&api_key=${apiKey}&format=json`;
    https.get(url, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          const json = JSON.parse(data);
          resolve(!json.error);
        } catch {
          resolve(false);
        }
      });
    }).on("error", () => resolve(false));
  });
}

function getImageKeyForTrack(artist, album) {
  if (EFAS_ARTISTS.includes(artist.toLowerCase())) {
    const key = ALBUM_KEYS[album.toLowerCase()];
    if (key) return key;
    return "efas_oops";
  }
  return "oops";
}

function fetchNowPlaying(apiKey, username) {
  return new Promise((resolve, reject) => {
    const url = `https://ws.audioscrobbler.com/2.0/?method=user.getrecenttracks&user=${username}&api_key=${apiKey}&format=json&limit=1`;
    https.get(url, (res) => {
      let data = "";
      res.on("data", (chunk) => (data += chunk));
      res.on("end", () => {
        try {
          const json = JSON.parse(data);
          const tracks = json.recenttracks?.track;
          if (!tracks || tracks.length === 0) return resolve(null);
          const latest = Array.isArray(tracks) ? tracks[0] : tracks;
          const isNowPlaying = latest["@attr"]?.nowplaying === "true";
          if (!isNowPlaying) return resolve(null);
          resolve({
            name: latest.name,
            artist: latest.artist["#text"],
            album: latest.album["#text"],
          });
        } catch (e) {
          reject(e);
        }
      });
    }).on("error", reject);
  });
}

async function updatePresence(apiKey, username) {
  try {
    const track = await fetchNowPlaying(apiKey, username);
    const trackChanged =
      track?.name !== lastTrack?.name ||
      track?.artist !== lastTrack?.artist;
    if (!trackChanged) return;
    lastTrack = track;
    let imageKey = "oops";
    let imageText = "oops";
    let details = "Not listening to anything";
    let state = undefined;
    if (track) {
      imageKey = getImageKeyForTrack(track.artist, track.album);
      imageText = track.album || track.artist;
      details = track.name;
      state = `by ${track.artist}`;
      console.log(`you are now listening to \x1b[38;2;179;0;0m${track.name}\x1b[0m by \x1b[38;2;179;0;0m${track.artist}\x1b[0m`);
    }
    const is1237 = track?.name === "12:37";
    const timestamp1237 = new Date(Date.now() - (12 * 60 + 37) * 60 * 1000);
    await rpc.setActivity({
      details,
      state,
      startTimestamp: is1237 ? timestamp1237 : new Date(),
      largeImageKey: imageKey,
      largeImageText: imageText,
      instance: false,
    });
  } catch (err) {
    console.error("Error updating presence:", err);
  }
}

async function setup() {
  const config = loadConfig();
  if (config) return config;

  console.log("you will need to install node.js to start pulse");
  console.log("you will also need a last.fm API key and username.");
  console.log("please enter your last.fm username:")
  const username = await prompt("");
  console.log("please paste your last.fm API key here:")
  const apiKey = await prompt("");

  const valid = await validateApiKey(apiKey, username);
  if (!valid) {
    console.log("invalid api key or username :(");
    process.exit(1);
  }

  saveConfig(apiKey, username);
  console.log("enjoy pulse :3");
  return { apiKey, username };
}

async function main() {
  const { apiKey, username } = await setup();

  rpc.on("ready", () => {
    console.log("started pulsing.");
    updatePresence(apiKey, username);
    setInterval(() => updatePresence(apiKey, username), 15_000);
  });

  rpc.login({ clientId }).catch(console.error);
}

main();