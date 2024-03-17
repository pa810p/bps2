import React, { useState, useEffect } from "react"

import { Routes, Route, Link } from "react-router-dom";

import './App.css';

import { RenderSugar } from "./pages/sugar";
import { RenderPressure } from "./pages/pressure";
import { RenderWelcome } from "./pages/welcome";
import { RenderCholesterol } from "./pages/cholesterol";
import { RenderUrineAcid } from "./pages/urine_acid";
import { RenderBloodNavBar } from "./components/BloodNavBar";
import { RenderCharts } from "./pages/charts";

export const App = () => {

  useEffect(() => {
    document.title = 'BPS2';
  }, []);

  return (
    <div>
      { RenderBloodNavBar() }  
      <Routes>
        <Route path="/" element={RenderWelcome()}></Route>
        <Route path="/pressure" element={RenderPressure()}></Route>
        <Route path="/sugar" element={RenderSugar()}></Route>
        <Route path="/urine_acid" element={RenderUrineAcid()}></Route>
        <Route path="/cholesterol" element={RenderCholesterol()}></Route>
        <Route path="/charts" element={RenderCharts()}></Route>
      </Routes>  
    </div>
  )
}
