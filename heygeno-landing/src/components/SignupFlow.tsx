import { useState } from 'react';
import { ImageCarousel } from './ImageCarousel';
import { SignupForm } from './SignupForm';

export function SignupFlow() {
  return (
    <div className="flex min-h-screen flex-col lg:flex-row">
      {/* Left Panel - Visual Storytelling */}
      <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-indigo-600 via-purple-600 to-pink-500">
        <ImageCarousel />
      </div>

      {/* Right Panel - Signup Form */}
      <div className="flex-1 flex items-center justify-center p-6 lg:p-12 bg-white">
        <div className="w-full max-w-md">
          <SignupForm />
        </div>
      </div>
    </div>
  );
}
