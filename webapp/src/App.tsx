import React, { useState, useEffect } from "react"

import { Routes, Route, Link } from "react-router-dom";

import './App.css';

import { renderSugar } from "./pages/sugar";
import { renderPressure } from "./pages/pressure";
import { renderWelcome } from "./pages/welcome";
import { renderBloodNavBar } from "./components/BloodNavBar";

export const App = () => {
  return (
    <div>
      { renderBloodNavBar() }  
      <Routes>
        <Route path="/pressure" element={renderPressure()}></Route>
        <Route path="/sugar" element={renderSugar()}></Route>
        <Route path="/welcome" element={renderWelcome()}></Route>
        <Route path="/" element={renderWelcome()}></Route>
      </Routes>  
    </div>
  )
}
