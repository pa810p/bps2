import React from "react";

import Typography from "@mui/material/Typography";
import AppBar from "@mui/material/AppBar";
import Container from "@mui/material/Container";
import Toolbar from "@mui/material/Toolbar";
import i18n from "i18next";
import { useTranslation } from "react-i18next";
import Grid from "@mui/material/Grid";
import Button from "@mui/material/Button";
import { useNavigate } from "react-router-dom";


export const renderWelcome = () => {
    const { t } = useTranslation('translation')
    
    console.log("Welcome render")

    const navigate = useNavigate();

    const handlePressureClick = () => {
        console.log('handlePressureClick');
        navigate('/pressure');
    }

    const handleSugarClick = () => {
        console.log('handleSugarClick');
        navigate('/sugar');
    }

    const handleUrineAcidClick = () => {
        console.log('handleUrineAcidClick');
        navigate('/urine_acid');
    }

    const handleCholesterolClick = () => {
        console.log('handleUrineAcidClick');
        navigate('/cholesterol');
    }
   
    const handleGraphsClick = () => {
        console.log('handleGraphsClick');
    }

    i18n.addResource('gb', 'translation', 'welcome', 'Blood Parameters Storage System (BPS2)');
    i18n.addResource('de', 'translation', 'welcome', 'BPS2');
    i18n.addResource('pl', 'translation', 'welcome', 'BPS2');

    i18n.addResource('gb', 'translation', 'pressure', 'Pressure');
    i18n.addResource('de', 'translation', 'pressure', 'Druck');
    i18n.addResource('pl', 'translation', 'pressure', 'Ciśnienie');

    i18n.addResource('gb', 'translation', 'sugar', 'Sugar');
    i18n.addResource('de', 'translation', 'sugar', 'Zucker');
    i18n.addResource('pl', 'translation', 'sugar', 'Cukier');

    i18n.addResource('gb', 'translation', 'urine acid', 'Urine acid');
    i18n.addResource('de', 'translation', 'urine acid', 'Harnsäure');
    i18n.addResource('pl', 'translation', 'urine acid', 'Kwas moczowy');

    i18n.addResource('gb', 'translation', 'cholesterol', 'Cholesterol');
    i18n.addResource('de', 'translation', 'cholesterol', 'Cholesterol');
    i18n.addResource('pl', 'translation', 'cholesterol', 'Cholesterol');

    i18n.addResource('gb', 'translation', 'charts', 'Charts');
    i18n.addResource('de', 'translation', 'charts', 'Diagramme');
    i18n.addResource('pl', 'translation', 'charts', 'Wykresy');

    return (
        <AppBar position="static">
        <Container maxWidth="lg">
            <Grid container spacing={2}>
                <Grid item xs={4}>
                    <Button variant="text" size="small"
                        sx={{":hover": {
                                bgcolor: "#AF5",
                                color: "white"
                                }}}
                        style={{display: "flex", flexDirection: "column", textTransform: "none"}}
                        onClick={handlePressureClick}>
                        <img src="logo512.png" width="100" alt="folder"
                            // onMouseOver={handleMouseOver}
                            />
                        <label>{t('pressure')}</label>
                    </Button>
                </Grid>
                <Grid item xs={4}>
                    <Button variant="text" size="small"
                        sx={{":hover": {
                                bgcolor: "#AF5",
                                color: "white"
                                }}}
                                style={{display: "flex", flexDirection: "column", textTransform: "none"}}
                        onClick={handleSugarClick}>
                        <img src="logo512.png" width="100" alt="folder"/>
                        <label>{t('sugar')}</label>
                    </Button>
                </Grid>
                <Grid item xs={4}>
                    <Button variant="text" size="small"
                    sx={{":hover": {
                                bgcolor: "#AF5",
                                color: "white"
                                }}}
                                style={{display: "flex", flexDirection: "column", textTransform: "none"}}
                        onClick={handleUrineAcidClick}>
                        <img src="logo512.png" width="100" alt="folder"/>
                        <label>{t('urine acid')}</label>
                    </Button>
                </Grid>
                <Grid item xs={4}>
                    <Button variant="text" size="small"
                        sx={{":hover": {
                                bgcolor: "#AF5",
                                color: "white"
                                }}}
                                style={{display: "flex", flexDirection: "column", textTransform: "none"}}
                        onClick={handleCholesterolClick}>
                        <img src="logo512.png" width="100" alt="folder"/>
                        <label>{t('cholesterol')}</label>
                    </Button>
                </Grid>
                <Grid item xs={4}>
                    <Button variant="text" size="small"
                        sx={{":hover": {
                                bgcolor: "#AF5",
                                color: "white"
                                }}}
                                style={{display: "flex", flexDirection: "column", textTransform: "none"}}
                        onClick={handleGraphsClick}
                        // onMouseOver={handleMouseOver}
                        >
                        <img src="logo512.png" width="100" alt="folder"/>
                        <label>{t('charts')}</label>
                    </Button>
                </Grid>
            </Grid>
        </Container>
    </AppBar>
    )
}

