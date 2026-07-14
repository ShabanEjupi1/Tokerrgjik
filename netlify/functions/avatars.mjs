import { neon } from './db.mjs';

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  console.error('❌ DATABASE ERROR: No connection string found! Set DATABASE_URL.');
}

const sql = connectionString ? neon(connectionString) : null;

export default async (req, res) => {
  // Enable CORS
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }
  
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }
  
  try {
    // Check if database is configured
    if (!sql) {
      return {
        statusCode: 500,
        headers,
        body: JSON.stringify({ 
          error: 'Database not configured. Set DATABASE_URL.' 
        }),
      };
    }

    const { action, image, filename, username, avatar_url } = req.body;
    
    // UPLOAD AVATAR
    if (action === 'upload') {
      // In a real implementation, you would:
      // 1. Decode the base64 image
      // 2. Upload to Cloudinary/S3/Firebase Storage
      // 3. Return the public URL
      
      // For demo, we'll use a placeholder service (or you can integrate Cloudinary here)
      // Using imgbb.com as a simple image host example
      
      if (!image) {
        return res.status(400).json({ error: 'No image provided' });
      }
      
      // Here you would integrate with Cloudinary:
      // const cloudinary = require('cloudinary').v2;
      // cloudinary.config({ ... });
      // const result = await cloudinary.uploader.upload(`data:image/jpeg;base64,${image}`);
      // const url = result.secure_url;
      
      // For now, return a demo URL (students should implement real upload)
      const demoUrl = `https://ui-avatars.com/api/?name=${filename}&background=random&size=200`;
      
      return res.status(200).json({
        url: demoUrl,
        message: 'Avatar uploaded successfully (demo mode - integrate Cloudinary/S3 for production)'
      });
    }
    
    // UPDATE USER AVATAR
    if (action === 'update_avatar') {
      if (!username || !avatar_url) {
        return res.status(400).json({ error: 'Missing username or avatar_url' });
      }
      
      await sql`
        UPDATE users
        SET avatar_url = ${avatar_url}
        WHERE username = ${username}
      `;
      
      return res.status(200).json({ message: 'Avatar updated successfully' });
    }
    
    return res.status(400).json({ error: 'Invalid action' });
    
  } catch (error) {
    console.error('Avatar error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
};
