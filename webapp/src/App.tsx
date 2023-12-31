import React, { useState, useEffect } from "react"

import { Routes, Route, Link } from "react-router-dom";

import './App.css';

import { renderSugar } from "./pages/sugar";
import { renderPressure } from "./pages/pressure";
import { renderWelcome } from "./pages/welcome";
import { renderCholesterol } from "./pages/cholesterol";
import { renderUrineAcid } from "./pages/urine_acid";
import { renderBloodNavBar } from "./components/BloodNavBar";
import { renderCharts } from "./pages/charts";

export const App = () => {
  return (
    <div>
      { renderBloodNavBar() }  
      <Routes>
        <Route path="/" element={renderWelcome()}></Route>
        <Route path="/pressure" element={renderPressure()}></Route>
        <Route path="/sugar" element={renderSugar()}></Route>
        <Route path="/urine_acid" element={renderUrineAcid()}></Route>
        <Route path="/cholesterol" element={renderCholesterol()}></Route>
        <Route path="/charts" element={renderCharts()}></Route>
      </Routes>  
    </div>
  )
}
