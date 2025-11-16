const fs = require('fs');
const path = require('path');

// Source APK folder (adjust if folder name changes)
const destDir = path.resolve(__dirname, '..', 'build', 'web', 'apks');

// Allow override via env var APK_SRC
let srcDir = process.env.APK_SRC;
if (srcDir) srcDir = path.resolve(srcDir);

// Default candidate paths to search if APK_SRC not provided
const candidates = [];
// specific folder name used in workspace sometimes
const specificName = 'android-apks-91dfc8a013a9fd3dacd648d4a222dc543476e054';
candidates.push(path.resolve(__dirname, '..', specificName));

// project root: look for any folder starting with android-apks
try {
  const items = fs.readdirSync(path.resolve(__dirname, '..'));
  items.forEach(it => {
    if (it.toLowerCase().startsWith('android-apks')) {
      candidates.push(path.resolve(__dirname, '..', it));
    }
  });
} catch (e) {
  // ignore
}

// common user Downloads location (may not exist in some environments)
try {
  const home = process.env.USERPROFILE || process.env.HOME;
  if (home) candidates.push(path.resolve(home, 'Downloads', specificName));
} catch (e) {}

if (!srcDir) {
  // pick the first candidate that exists
  srcDir = candidates.find(p => {
    try { return fs.existsSync(p) && fs.statSync(p).isDirectory(); } catch (e) { return false; }
  });
}

function copyRecursiveSync(src, dest) {
  const exists = fs.existsSync(src);
  const stats = exists && fs.statSync(src);
  const isDirectory = exists && stats.isDirectory();
  if (isDirectory) {
    if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
    fs.readdirSync(src).forEach(function(childItemName) {
      copyRecursiveSync(path.join(src, childItemName), path.join(dest, childItemName));
    });
  } else {
    // copy file
    const destDirPath = path.dirname(dest);
    if (!fs.existsSync(destDirPath)) fs.mkdirSync(destDirPath, { recursive: true });
    fs.copyFileSync(src, dest);
    console.log('Copied:', src, '->', dest);
  }
}

if (!srcDir) {
  console.error('Source APK directory not found. Tried these locations:');
  console.error(candidates.join('\n'));
  console.error('\nYou can either:');
  console.error('- Place your APKs in a folder named starting with "android-apks" inside the project root, or');
  console.error('- Set environment variable APK_SRC to the path of your APK folder and re-run this script.');
  process.exit(1);
}

console.log('Copying APKs from', srcDir, 'to', destDir);
copyRecursiveSync(srcDir, destDir);
console.log('Done.');
