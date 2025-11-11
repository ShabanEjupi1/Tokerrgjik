/**
 * Test email configuration
 */

import 'dotenv/config';

console.log('📧 Email Configuration Check');
console.log('================================\n');

const config = {
  APP_PASSWORD: process.env.APP_PASSWORD,
  GMAIL_USER: process.env.GMAIL_USER,
  FROM_EMAIL: process.env.FROM_EMAIL,
  SMTP_HOST: process.env.SMTP_HOST,
  SMTP_PORT: process.env.SMTP_PORT,
};

console.log('Environment Variables:');
console.log('----------------------');
console.log('APP_PASSWORD:', config.APP_PASSWORD ? `✅ Set (${config.APP_PASSWORD.length} chars)` : '❌ NOT SET');
console.log('GMAIL_USER:', config.GMAIL_USER || '❌ NOT SET');
console.log('FROM_EMAIL:', config.FROM_EMAIL || '❌ NOT SET');
console.log('SMTP_HOST:', config.SMTP_HOST || '❌ NOT SET');
console.log('SMTP_PORT:', config.SMTP_PORT || '❌ NOT SET');

console.log('\n📋 Summary:');
console.log('-----------');
if (config.APP_PASSWORD && config.GMAIL_USER) {
  console.log('✅ Email configuration is COMPLETE');
  console.log('   Emails will be sent via SMTP');
} else {
  console.log('⚠️  Email configuration is INCOMPLETE');
  console.log('   Missing:', [
    !config.APP_PASSWORD && 'APP_PASSWORD',
    !config.GMAIL_USER && 'GMAIL_USER'
  ].filter(Boolean).join(', '));
  console.log('   Emails will only be logged to console');
}

console.log('\n💡 To send actual emails:');
console.log('   1. Ensure APP_PASSWORD and GMAIL_USER are set in .env file');
console.log('   2. Set the same variables in Netlify dashboard');
console.log('   3. Users must have email addresses in their profiles');
console.log('\n');
