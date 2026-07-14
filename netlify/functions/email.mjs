import { neon } from './db.mjs';
import nodemailer from 'nodemailer';

const sql = neon(process.env.DATABASE_URL);

// SMTP configuration. We send through our own Mailcow, so the from-address must
// be a real mailbox on a domain Mailcow signs with DKIM - otherwise the mail is
// accepted here and then dropped as spam downstream.
const EMAIL_CONFIG = {
  FROM_EMAIL: process.env.SMTP_USER || 'tokerrgjik@shabanejupi.tech',
  FROM_NAME: 'Tokerrgjik',
  SMTP_HOST: process.env.SMTP_HOST || 'mail.spacecode.tech',
  SMTP_PORT: parseInt(process.env.SMTP_PORT || '587', 10),
  SMTP_USER: process.env.SMTP_USER,
  SMTP_PASS: process.env.SMTP_PASS,
};

// Built once: nodemailer pools connections, and rebuilding per send would open a
// new SMTP session for every email.
let transporter;

const createTransporter = () => {
  if (transporter !== undefined) return transporter;

  if (!EMAIL_CONFIG.SMTP_USER || !EMAIL_CONFIG.SMTP_PASS) {
    console.warn('⚠️  SMTP_USER/SMTP_PASS not set. Emails will only be logged.');
    transporter = null;
    return transporter;
  }

  // 465 is implicit TLS; 587 upgrades via STARTTLS.
  transporter = nodemailer.createTransport({
    host: EMAIL_CONFIG.SMTP_HOST,
    port: EMAIL_CONFIG.SMTP_PORT,
    secure: EMAIL_CONFIG.SMTP_PORT === 465,
    requireTLS: EMAIL_CONFIG.SMTP_PORT === 587,
    auth: {
      user: EMAIL_CONFIG.SMTP_USER,
      pass: EMAIL_CONFIG.SMTP_PASS,
    },
    pool: true,
  });

  return transporter;
};

// Send email via SMTP
async function sendEmail(to, subject, html) {
  console.log('\n========================================');
  console.log('📧 EMAIL NOTIFICATION');
  console.log('========================================');
  console.log(`To: ${to}`);
  console.log(`From: ${EMAIL_CONFIG.FROM_NAME} <${EMAIL_CONFIG.FROM_EMAIL}>`);
  console.log(`Subject: ${subject}`);
  console.log('----------------------------------------');

  const mailer = createTransporter();

  if (!mailer) {
    console.log('⚠️  Email SMTP not configured; nothing sent.');
    return false;
  }

  try {
    const info = await mailer.sendMail({
      from: `"${EMAIL_CONFIG.FROM_NAME}" <${EMAIL_CONFIG.FROM_EMAIL}>`,
      to,
      subject,
      html,
    });

    console.log('✅ Email sent. Message ID:', info.messageId);
    return true;
  } catch (error) {
    console.error('❌ Error sending email:', error.message);
    return false;
  }
}

/**
 * Email endpoint handler
 * Sends email notifications to users
 */
export async function handler(event, context) {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Content-Type': 'application/json',
  };

  if (event.httpMethod === 'OPTIONS') {
    return { statusCode: 200, headers, body: '' };
  }
  
  if (event.httpMethod !== 'POST') {
    return {
      statusCode: 405,
      headers,
      body: JSON.stringify({ error: 'Method not allowed' }),
    };
  }
  
  try {
    const data = JSON.parse(event.body);
    console.log('📧 Email function called');
    console.log('Request body:', JSON.stringify(data, null, 2));
    
    const { type, username, data: emailData } = data;
    
    if (!username || !type) {
      console.error('❌ Missing required fields');
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Missing required fields: username and type' }),
      };
    }
    
    // Get user email
    console.log('🔍 Looking up user:', username);
    const user = await sql`
      SELECT email, username FROM users
      WHERE username = ${username}
    `;
    
    if (user.length === 0) {
      console.error('❌ User not found:', username);
      return {
        statusCode: 404,
        headers,
        body: JSON.stringify({ error: 'User not found', username }),
      };
    }
    
    const userEmail = user[0].email;
    const fullName = username;
    
    console.log('✅ User found. Email:', userEmail);
    
    // Check if user has an email address
    if (!userEmail || userEmail.trim() === '') {
      console.error('❌ User has no email address');
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ 
          error: 'User has no email address registered',
          username,
          note: 'User must update their profile to add an email address'
        }),
      };
    }
    
    let subject = '';
    let html = '';
    
    // FRIEND REQUEST
    if (type === 'friend_request') {
      const fromUsername = emailData.from_username;
      subject = `🎮 Kërkesë miqësie nga ${fromUsername} - TokerrGjik`;
      html = `
        <h2>Përshëndetje ${fullName}!</h2>
        <p><strong>${fromUsername}</strong> dëshiron të bëhet miku juaj në TokerrGjik!</p>
        <p>Hyni në aplikacion për të pranuar ose refuzuar kërkesën.</p>
        <br>
        <p>Faleminderit që luani TokerrGjik! 🎮</p>
      `;
    }
    
    // FRIEND REQUEST ACCEPTED
    else if (type === 'friend_request_accepted') {
      const acceptedBy = emailData.accepted_by;
      subject = `✅ ${acceptedBy} pranoi kërkesën tuaj - TokerrGjik`;
      html = `
        <h2>Lajme të mira ${fullName}!</h2>
        <p><strong>${acceptedBy}</strong> pranoi kërkesën tuaj të miqësisë!</p>
        <p>Tani mund të luani së bashku dhe të sfidoni njëri-tjetrin.</p>
        <br>
        <p>Suksese në lojëra! 🎮🎉</p>
      `;
    }
    
    // GAME INVITE
    else if (type === 'game_invite') {
      const fromUsername = emailData.from_username;
      subject = `🎲 Ftesë loje nga ${fromUsername} - TokerrGjik`;
      html = `
        <h2>Përshëndetje ${fullName}!</h2>
        <p><strong>${fromUsername}</strong> ju fton të luani një lojë TokerrGjik!</p>
        <p>Hyni në aplikacion për të filluar lojën.</p>
        <br>
        <p>Suksese! 🏆</p>
      `;
    }
    
    // ACHIEVEMENT UNLOCKED
    else if (type === 'achievement_unlocked') {
      const achievementTitle = emailData.achievement_title;
      const achievementIcon = emailData.achievement_icon || '🏆';
      subject = `${achievementIcon} Arritje e re e fituar - TokerrGjik`;
      html = `
        <h2>Urime ${fullName}!</h2>
        <p>Keni hapur një arritje të re:</p>
        <h3>${achievementIcon} ${achievementTitle}</h3>
        <p>${emailData.achievement_description || ''}</p>
        <br>
        <p>Vazhdoni të luani për të hapur më shumë arritje! 🎮</p>
      `;
    }
    
    // PRO PURCHASE CONFIRMATION
    else if (type === 'pro_purchase') {
      const months = emailData.months || 1;
      const amount = emailData.amount || '€2.99';
      subject = `✅ Konfirmim blerje PRO - TokerrGjik`;
      html = `
        <h2>Faleminderit ${fullName}!</h2>
        <p>Blerja juaj është konfirmuar:</p>
        <ul>
          <li><strong>Pajtime:</strong> TokerrGjik PRO</li>
          <li><strong>Kohëzgjatja:</strong> ${months} muaj</li>
          <li><strong>Shuma:</strong> ${amount}</li>
        </ul>
        <p>Tani keni qasje në:</p>
        <ul>
          <li>✨ Pa reklama</li>
          <li>🎨 Themes të personalizuara</li>
          <li>📊 Statistika të avancuara</li>
          <li>👑 Statusi PRO në Leaderboard</li>
        </ul>
        <br>
        <p>Shijoni përvojën PRO! 🚀</p>
      `;
    }
    
    // COINS PURCHASE CONFIRMATION
    else if (type === 'coins_purchase') {
      const coins = emailData.coins || 100;
      const amount = emailData.amount || '€0.99';
      subject = `💰 Konfirmim blerje monedhash - TokerrGjik`;
      html = `
        <h2>Faleminderit ${fullName}!</h2>
        <p>Blerja juaj është konfirmuar:</p>
        <ul>
          <li><strong>Monedha:</strong> ${coins} monedha</li>
          <li><strong>Shuma:</strong> ${amount}</li>
        </ul>
        <p>Monedhat janë shtuar në llogarinë tuaj!</p>
        <br>
        <p>Argëtim në lojë! 🎮</p>
      `;
    }
    
    // PASSWORD RESET
    else if (type === 'password_reset') {
      const resetToken = emailData.reset_token || 'DEMO_TOKEN';
      const resetLink = `https://tokerrgjik.netlify.app/reset-password?token=${resetToken}`;
      subject = `🔐 Rivendosni fjalëkalimin - TokerrGjik`;
      html = `
        <h2>Përshëndetje ${fullName}!</h2>
        <p>Keni kërkuar të rivendosni fjalëkalimin tuaj.</p>
        <p>Klikoni linkun më poshtë për të vazhduar:</p>
        <p><a href="${resetLink}" style="padding: 10px 20px; background: #667eea; color: white; text-decoration: none; border-radius: 5px;">Rivendos Fjalëkalimin</a></p>
        <p>Nëse nuk keni kërkuar këtë, ju lutemi injoroni këtë email.</p>
        <p><em>Linku është i vlefshëm për 24 orë.</em></p>
      `;
    }
    
    else {
      console.error('❌ Invalid email type:', type);
      return {
        statusCode: 400,
        headers,
        body: JSON.stringify({ error: 'Invalid email type', type }),
      };
    }
    
    // Send email
    console.log('📤 Sending email to:', userEmail);
    const emailSent = await sendEmail(userEmail, subject, html);

    // Report what actually happened. This used to always claim success, which
    // hid the fact that no mail was going out at all.
    return {
      statusCode: emailSent ? 200 : 502,
      headers,
      body: JSON.stringify({
        message: emailSent ? 'Email sent successfully' : 'Email could not be sent',
        to: userEmail,
        type,
        emailConfigured: !!(EMAIL_CONFIG.SMTP_USER && EMAIL_CONFIG.SMTP_PASS),
      }),
    };

  } catch (error) {
    console.error('❌ Email function error:', error);
    console.error('Error stack:', error.stack);
    return {
      statusCode: 500,
      headers,
      body: JSON.stringify({ 
        error: 'Internal server error', 
        message: error.message,
        stack: process.env.NODE_ENV === 'development' ? error.stack : undefined
      }),
    };
  }
}
