import React from "react";

import Typography from "@mui/material/Typography";
import AppBar from "@mui/material/AppBar";
import Container from "@mui/material/Container";
import Toolbar from "@mui/material/Toolbar";
import i18n from "i18next";
import { useTranslation } from "react-i18next";


export const renderCharts = () => {
    const { t } = useTranslation('translation')
    console.log("Charts render")

    i18n.addResource('gb', 'translation', 'charts', 'Charts');
    i18n.addResource('de', 'translation', 'charts', 'Diagramme');
    i18n.addResource('pl', 'translation', 'charts', 'Wykresy');

    return (
        <AppBar position="static">
        <Container maxWidth="lg">
            <Toolbar>
                <Typography sx={{flexGrow: 1, fontWeight: 700}}>
                    {t('charts')}
                </Typography>
            </Toolbar>
        </Container>
        </AppBar>
    )
}