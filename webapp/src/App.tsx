import React, { } from 'react';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';

import { RenderBloodNavBar } from './components/BloodNavBar';
import { Sugar } from "./pages/sugar";
import { Pressure } from "./pages/pressure";
import { UrineAcid } from './pages/urine_acid';
import { Cholesterol } from './pages/cholesterol';
import { Welcome } from './pages/welcome';
import { Charts } from './pages/charts';

export const App: React.FC = () => {
  return (
    <Router>
        <div><RenderBloodNavBar /> </div>

        <Routes>
          <Route path="/" element={<Welcome />} />
          <Route path="/pressure" element={<Pressure />} />
          <Route path="/urine_acid" element={<UrineAcid />} />
          <Route path="/cholesterol" element={<Cholesterol />} />
          <Route path="/sugar" element={<Sugar />} />
          <Route path="/charts" element={<Charts />} />
        </Routes>
    </Router>
    
  );
};
