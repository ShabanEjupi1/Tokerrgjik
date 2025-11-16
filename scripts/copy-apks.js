const fs = require('fs');
const path = require('path');

// Source APK folder (adjust if folder name changes)
const srcDir = path.resolve(__dirname, '..', 'android-apks-91dfc8a013a9fd3dacd648d4a222dc543476e054');
const destDir = path.resolve(__dirname, '..', 'build', 'web', 'apks');

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

if (!fs.existsSync(srcDir)) {
  console.error('Source APK directory not found:', srcDir);
  process.exit(1);
}

console.log('Copying APKs from', srcDir, 'to', destDir);
copyRecursiveSync(srcDir, destDir);
console.log('Done.');
