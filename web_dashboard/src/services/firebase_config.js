import { initializeApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

// Standard Firebase App Configuration
const firebaseConfig = {
  apiKey: process.env.VITE_FIREBASE_API_KEY || "AIzaSy_CREPISENSE_MOCK_API_KEY",
  authDomain: process.env.VITE_FIREBASE_AUTH_DOMAIN || "crepisense-ner.firebaseapp.com",
  projectId: process.env.VITE_FIREBASE_PROJECT_ID || "crepisense-ner",
  storageBucket: process.env.VITE_FIREBASE_STORAGE_BUCKET || "crepisense-ner.appspot.com",
  messagingSenderId: process.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "1029384756",
  appId: process.env.VITE_FIREBASE_APP_ID || "1:1029384756:web:abcdef123456"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
