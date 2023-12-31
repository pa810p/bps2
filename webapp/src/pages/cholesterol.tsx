import React from "react";

import Typography from "@mui/material/Typography";
import AppBar from "@mui/material/AppBar";
import Container from "@mui/material/Container";
import Toolbar from "@mui/material/Toolbar";
import i18n from "i18next";
import { useTranslation } from "react-i18next";


export const renderCholesterol = () => {
    const { t } = useTranslation('translation')
    console.log("Cholesterol render")

    i18n.addResource('gb', 'translation', 'cholesterol', 'Cholesterol');
    i18n.addResource('de', 'translation', 'cholesterol', 'Cholesterol');
    i18n.addResource('pl', 'translation', 'cholesterol', 'Cholesterol');

    return (
        <AppBar position="static">
        <Container maxWidth="lg">
            <Toolbar>
                <Typography sx={{flexGrow: 1, fontWeight: 700}}>
                    {t('cholesterol')}
                </Typography>
            </Toolbar>
        </Container>
        </AppBar>
    )
}